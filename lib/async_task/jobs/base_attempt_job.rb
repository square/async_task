module AsyncTask
  module BaseAttemptJob
    extend ActiveSupport::Concern

    included do
      include BaseJob

      queue_as :default

      # @override
      private def lock_key
        [self.class.name, @task.id]
      end
    end

    def perform(task)
      @task = task
      unless_already_executing { @task.perform! if @task.reload.pending? }
    end
  end
end
