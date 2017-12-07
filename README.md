# AsyncTask

[![Gem Version](https://badge.fury.io/rb/async_task.svg)](http://badge.fury.io/rb/async_task)
[![License](https://img.shields.io/badge/license-Apache-green.svg?style=flat)](https://github.com/square/async_task/blob/master/LICENSE)

Lightweight, asynchronous, and database-backed execution of singleton methods.

This gem provides generators and mixins to queue up tasks in database transactions to be performed
later. Doing so prevents (1) tasks from being run twice if performed within a transaction and (2)
tasks from synchronously blocking.

```ruby
transaction do
  order = Order.create!(number: 7355608)

  # RPC Call
  OrderClient.fulfill(customer_token: customer_token, order_number: order.number)

  raise
end
```

Despite database transaction rolling back the creation of the `Order` record, the RPC call executes.
This problem becomes more difficult in nested transactions. To avoid doing something regrettable, we
create an `AsyncTask::Attempt` record inside the database. These records are then performed at a
later time using a job:

```ruby
transaction do
  order = Order.create!(number: 1)

  # To be performed by a job later
  AsyncTask::Attempt.create!(
    target: OrderClient,
    method_name: :fulfill,
    method_args: { customer_token: customer_token, order_number: order.number },
  )

  raise
end
```

The above pattern ensures we will not act when there is a rollback later in the transaction.

The gem provides the following:

* Models
  * Generators for the `AsyncTask::Attempt` migration, model, factory, and specs.
  * Choice between using async tasks with encrypted or unencrypted method arguments.
  * Tracking completion using `completed_at`.
  * Fields for `target`, `method_name`, and `method_args`.
  * `AsyncTask::BaseAttempt` mixin to provide model methods.
  * A `num_attempts` field gives you flexibility to handle retries and other failure scenarios.
  * `status` and `completed_at` are fields that track state.
  * `idempotence_token` field for rolling your own presence, uniqueness, or idempotence checks.

* Jobs
  * Generators for `AsyncTask::AttemptJob`, `AsyncTask::AttemptBatchJob`, and their specs.
  * `AsyncTask::BaseAttemptJob` and `AsyncTask::BaseAttemptBatchJob` mixins.

## Getting Started

1. Add the gem to your application's Gemfile and execute `bundle install` to install it:

```ruby
gem 'async_task'
```

2. Generate migrations, base models, jobs, and specs. Feel free to add any additional columns you
need to the generated migration file:

`$ rails g async_task:install`

3. Rename the model and migrations as you see fit. Make sure your model contains
`include AsyncTask::BaseAttempt`. Use `self.table_name=` if necessary.

```ruby
class AsyncTask::Attempt < ApplicationRecord
  include AsyncTask::BaseAttempt
end
```

4. Implement the `handle_perform_error` in your `AsyncTask::Attempt` model. This methods is used by
`AsyncTask::BaseAttempt` when exceptions are thrown performing the task.

5. This gem provides no encryptor by default. Implement an encryptor (see below) if you need
encrypted params.

6. Create `AsyncTask::Attempt`s to be sent later by a job (generated) that includes a
`AsyncTask::BaseAttemptJob`:

```ruby
class AsyncTask::AttemptJob < ActiveJob::Base
  include AsyncTask::BaseAttemptJob
end
```

```ruby
AsyncTask::Attempt.create!(
  target: OrderClient,
  method_name: :fulfill,
  method_args: { customer_token: customer_token, order_number: order.number },
)
```

7. **Make sure to schedule the `AsyncTask::AttemptJob` to run frequently using something like [`Clockwork`](https://github.com/adamwiggins/clockwork).**

## Cautionary Situations When Using This Gem

### Idempotence

The `target`, `method_name`, and `method_args` should be idempotent because the
`AsyncTask::AttemptBatchJob` could schedule multiple `AsyncTask::AttemptJob`s if the job queue is
backed up.

### Nested Transactions

Task execution occurs inside of a `with_lock` block, which executes the body inside of a database
transaction. Keep in mind that transactions inside the `#{target}.#{method_name}` will be nested.
You may have to consider implementing `transaction(require: new)` or creating transactions in
separate threads.

## Cookbook

### Custom Encryptors

Implement the interface present in `AsyncTask::NullEncryptor` to provide your own encryptor.

```ruby
module AesEncryptor
  extend self

  def decrypt(content)
    AesClient.decrypt(content)
  end

  def encrypt(content)
    AesClient.encrypt(content)
  end
end
```

### Delayed Execution

Setting the `scheduled_at` field allows delayed execution to be possible. A task that has an
`scheduled_at` before `Time.current` will be executed by `AsyncTask::BaseAttemptBatchJob`.

### Handling AsyncTask::BaseAttempt Errors

```ruby
class AsyncTask::Attempt < ActiveRecord::Base
  include AsyncTask::BaseAttempt

  def handle_perform_error(error)
    Raven.capture_exception(error)
  end
end
```

Lastly, the `num_attempts` field in `AsyncTask::Attempt` allows you to track the number of attempts
the task has undergone. Use this to implement retries and permanent failure thresholds for your
tasks.

### Proper Usage of `expire!` / `fail!`

`expire!` should be used for tasks that should no longer be run.

`fail!` should be used to mark permanent failure for a task.

## Design Motivations

We're relying heavily on generators and mixins. Including the `AsyncTask::BaseAttempt` module allows
us to generate a model that can inherit from both `ActiveRecord::Base` (Rails 4) and
`ApplicationRecord` (Rails 5). The `BaseAttempt` module's methods can easily be overridden, giving
callers flexibility to handle errors, extend functionality, and inherit (STI). Lastly, the generated
migrations provide fields used by the `BaseAttempt` module, but the developer is free to add their
own fields and extend the module's methods while calling `super`.

## Development

* Install dependencies with `bin/setup`.
* Run tests/lints with `rake`
* For an interactive prompt that will allow you to experiment, run `bin/console`.

## Acknowledgments

* [RickCSong](https://github.com/RickCSong)

## License

```
Copyright 2017 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
