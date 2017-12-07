require 'rails/generators'
require 'rails/generators/active_record'

module AsyncTask
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('../templates/', __FILE__)

    desc 'Generates (but does not run) migrations to add the' \
         ' async_tasks table and creates the base model'

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def create_migration_file
      migration_template 'create_async_task_attempts.rb', 'db/migrate/create_async_task_attempts.rb'
    end

    def create_async_task_files
      template 'async_task_attempt.rb.erb', 'app/models/async_task/attempt.rb'
      template 'async_task_attempt_job.rb.erb', 'app/jobs/async_task/attempt_job.rb'
      template 'async_task_attempt_batch_job.rb.erb', 'app/jobs/async_task/attempt_batch_job.rb'

      if defined?(RSpec)
        template 'async_task_attempt_spec.rb.erb', 'spec/models/async_task/attempt_spec.rb'
        template 'async_task_attempt_job_spec.rb.erb', 'spec/jobs/async_task/attempt_job_spec.rb'
        template 'async_task_attempt_batch_job_spec.rb.erb', 'spec/jobs/async_task/attempt_batch_job_spec.rb'
      end

      if defined?(FactoryBot) || defined?(FactoryGirl)
        template 'async_task_attempts.rb.erb', 'spec/factories/async_task/attempts.rb'
      end
    end
  end
end
