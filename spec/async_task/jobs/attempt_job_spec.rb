require 'rails_helper'

RSpec.describe AsyncTask::AttemptJob, type: :job do
  describe '#perform' do
    let!(:task) do
      create(
        :async_task_attempt,
        target: TestClient,
        method_name: :do_something,
        method_args: { with: :foo, as: :bar },
      )
    end

    subject { described_class.new.perform(task) }

    before { allow(task).to receive(:perform!).and_call_original }

    it 'calls perform! on the async task' do
      subject
      expect(task).to have_received(:perform!)
    end
  end
end
