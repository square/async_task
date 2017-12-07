require 'rails_helper'

RSpec.describe AsyncTask::Attempt, type: :model do
  describe '#perform!' do
    subject { task.perform! }

    context 'when the task is not scheduled yet' do
      let!(:task) do
        create(
          :async_task_attempt,
          target: TestClient,
          method_name: :do_something,
          scheduled_at: Time.current + 1000.days
        )
      end

      it { expect { subject }.to_not change { task.num_attempts } }
    end

    context 'when the task is not pending' do
      let!(:task) do
        create(
          :async_task_attempt,
          :failed,
          target: TestClient,
          method_name: :do_something
        )
      end

      it { expect { subject }.to raise_error(AsyncTask::InvalidStateError) }
    end

    context 'when the task is pending and will run successfully' do
      let!(:task) do
        create(
          :async_task_attempt,
          target: TestClient,
          method_name: :do_something,
          method_args: { with: :foo, as: :bar },
        )
      end

      it { expect { subject }.to change { task.status }.from('pending').to('succeeded') }

      it { expect { subject }.to change { task.num_attempts }.from(0).to(1) }
    end

    context 'when the task fails with any error' do
      let!(:task) do
        create(:async_task_attempt, target: TestClient, method_name: :do_something)
      end

      before { allow(TestClient).to receive(:do_something).and_raise(RuntimeError) }

      it do
        expect { subject }.to raise_error(RuntimeError)
        expect(task.num_attempts).to eq(1)
      end
    end
  end

  describe '#expire!' do
    subject { task.expire! }

    context 'with a pending task' do
      let!(:task) { create(:async_task_attempt, target: TestClient, method_name: :do_something) }

      it 'sets completed_at and status to expired' do
        expect { subject }.to change { task.status }.from('pending').to('expired')
        expect(task.completed_at).not_to be_nil
      end
    end

    context 'with a non-pending task' do
      let!(:task) do
        create(
          :async_task_attempt,
          :failed,
          target: TestClient,
          method_name: :do_something,
        )
      end

      it { expect { subject }.to raise_error(AsyncTask::InvalidStateError) }
    end
  end

  describe '#fail!' do
    subject { task.fail! }

    context 'with a pending task' do
      let!(:task) { create(:async_task_attempt, target: TestClient, method_name: :do_something) }

      it 'sets completed_at and status to failed' do
        expect { subject }.to change { task.status }.from('pending').to('failed')
        expect(task.completed_at).not_to be_nil
      end
    end

    context 'with a non-pending task' do
      let!(:task) do
        create(
          :async_task_attempt,
          :failed,
          target: TestClient,
          method_name: :do_something,
        )
      end

      it { expect { subject }.to raise_error(AsyncTask::InvalidStateError) }
    end
  end
end
