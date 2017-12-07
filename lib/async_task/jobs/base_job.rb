module AsyncTask
  module BaseJob
    extend ActiveSupport::Concern

    private

    def lock_key
      self.class.name
    end

    def unless_already_executing(&block)
      result = ActiveRecord::Base.with_advisory_lock_result(lock_key, timeout_seconds: 0, &block)
      warn("AdvisoryLock owned by other instance of job: #{lock_key}. Exiting.") unless result.lock_was_acquired?
    end
  end
end
