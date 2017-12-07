FactoryBot.define do
  factory :async_task_attempt, class: 'AsyncTask::Attempt' do
    status { 'pending' }
    encryptor { AsyncTask::NullEncryptor }

    trait :succeeded do
      status { :succeeded }
      completed_at { Time.current }
    end

    trait :expired do
      status { 'expired' }
      completed_at { Time.current }
    end

    trait :failed do
      status { 'failed' }
      completed_at { Time.current }
    end
  end
end
