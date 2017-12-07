module AsyncTask
  module BaseAttemptBatchJob
    extend ActiveSupport::Concern

    included do
      include BaseJob

      queue_as :default
    end

    def perform
      unless_already_executing do
        ::AsyncTask::Attempt.pending.where('scheduled_at IS ? OR scheduled_at < ?', nil, Time.current).find_each do |task|
          ::AsyncTask::AttemptJob.perform_later(task)
        end
      end
    end
  end
end
