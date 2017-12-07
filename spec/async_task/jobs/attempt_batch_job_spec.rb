require 'rails_helper'

RSpec.describe AsyncTask::AttemptBatchJob, type: :job do
  describe '#perform' do
    subject { described_class.new.perform }

    context 'with tasks that are scheduled now' do
      let!(:task_1) do
        create(:async_task_attempt, target: TestClient, method_name: :do_something)
      end

      let!(:task_2) do
        create(:async_task_attempt, target: TestClient, method_name: :do_something)
      end

      let(:global_ids) { [{ '_aj_globalid' => 'gid://dummy/AsyncTask::Attempt/1' }, { '_aj_globalid' => 'gid://dummy/AsyncTask::Attempt/2' }] }

      it do
        subject
        expect(enqueued_jobs.map { |job| job.fetch(:args).first }).to include(*global_ids)
      end
    end

    context 'with a task that is not scheduled until later' do
      let!(:task) do
        create(
          :async_task_attempt,
          target: TestClient,
          method_name: :do_something,
          scheduled_at: Time.current + 1000.days
        )
      end

      it do
        subject
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
