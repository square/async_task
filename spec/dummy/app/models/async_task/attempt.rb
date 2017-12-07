class AsyncTask::Attempt < ApplicationRecord
  include AsyncTask::BaseAttempt

  # @override
  #
  # This method is used by AsyncTask::Base when #perform! fails.
  def handle_perform_error(error)
    raise error
  end
end
