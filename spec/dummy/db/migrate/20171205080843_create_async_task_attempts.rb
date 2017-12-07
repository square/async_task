class CreateAsyncTaskAttempts < ActiveRecord::Migration[5.1]
  def change
    create_table :async_task_attempts do |t|
      t.integer       :lock_version, null: false, default: 0

      t.string        :idempotence_token

      t.string        :status, null: false

      t.string        :target, null: false
      t.string        :method_name, null: false
      t.text          :method_args

      t.string        :encryptor, null: false

      t.integer       :num_attempts, null: false, default: 0

      t.datetime      :scheduled_at
      t.datetime      :completed_at

      t.timestamps    null: false

      t.index :status

      t.index %i[target method_name idempotence_token], unique: true, name: 'index_async_tasks_on_target_method_name_and_idempotence_token'

      t.index :scheduled_at
      t.index :completed_at
      t.index :created_at
      t.index :updated_at
    end
  end
end
