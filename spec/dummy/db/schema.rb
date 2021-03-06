# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_171_205_080_843) do
  create_table 'async_task_attempts', force: :cascade do |t|
    t.integer 'lock_version', default: 0, null: false
    t.string 'idempotence_token'
    t.string 'status', null: false
    t.string 'target', null: false
    t.string 'method_name', null: false
    t.text 'method_args'
    t.string 'encryptor', null: false
    t.integer 'num_attempts', default: 0, null: false
    t.datetime 'scheduled_at'
    t.datetime 'completed_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['completed_at'], name: 'index_async_task_attempts_on_completed_at'
    t.index ['created_at'], name: 'index_async_task_attempts_on_created_at'
    t.index ['scheduled_at'], name: 'index_async_task_attempts_on_scheduled_at'
    t.index ['status'], name: 'index_async_task_attempts_on_status'
    t.index %w[target method_name idempotence_token], name: 'index_async_tasks_on_target_method_name_and_idempotence_token', unique: true
    t.index ['updated_at'], name: 'index_async_task_attempts_on_updated_at'
  end
end
