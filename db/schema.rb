# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160415063131) do

  create_table "accounts", force: :cascade do |t|
    t.string   "account_type",     limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "accountable_id",   limit: 4,   null: false
    t.string   "accountable_type", limit: 255, null: false
  end

  add_index "accounts", ["accountable_id"], name: "index_accounts_on_accountable_id", using: :btree

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id",   limit: 4
    t.string   "trackable_type", limit: 255
    t.integer  "owner_id",       limit: 4
    t.string   "owner_type",     limit: 255
    t.string   "key",            limit: 255
    t.text     "parameters",     limit: 65535
    t.integer  "recipient_id",   limit: 4
    t.string   "recipient_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "balance_transfers", force: :cascade do |t|
    t.float    "total",                 limit: 24
    t.integer  "source_id",             limit: 4
    t.integer  "target_id",             limit: 4
    t.string   "description",           limit: 255
    t.datetime "created"
    t.integer  "source_transaction_id", limit: 4
    t.integer  "target_transaction_id", limit: 4
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "db_errors", force: :cascade do |t|
    t.text     "alert",          limit: 65535,                 null: false
    t.boolean  "checked",        limit: 1,     default: false, null: false
    t.datetime "last_run"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "line_number",    limit: 4
    t.integer  "transaction_id", limit: 4
  end

  create_table "invoices", force: :cascade do |t|
    t.string   "external_id", limit: 255
    t.boolean  "paid",        limit: 1,   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["external_id"], name: "index_invoices_on_external_id", unique: true, using: :btree

  create_table "orders", force: :cascade do |t|
    t.string   "name",               limit: 255,                                            null: false
    t.text     "description",        limit: 65535
    t.boolean  "paid",               limit: 1,                              default: false
    t.integer  "team_id",            limit: 4,                                              null: false
    t.integer  "invoice_id",         limit: 4
    t.decimal  "invoiced_budget",                  precision: 10, scale: 2,                 null: false
    t.decimal  "allocatable_budget",               precision: 10, scale: 2,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",          limit: 4
    t.decimal  "free_budget",                      precision: 10, scale: 2,                 null: false
    t.boolean  "completed",          limit: 1,                              default: false
    t.boolean  "internal_order",     limit: 1,                              default: false
    t.integer  "commission",         limit: 4
  end

  add_index "orders", ["invoice_id"], name: "index_orders_on_invoice_id", using: :btree
  add_index "orders", ["parent_id"], name: "index_orders_on_parent_id", using: :btree
  add_index "orders", ["team_id"], name: "index_orders_on_team_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "status_checks", force: :cascade do |t|
    t.datetime "start_run"
    t.datetime "finish_run"
  end

  create_table "task_orders", force: :cascade do |t|
    t.integer  "task_id",    limit: 4,                          null: false
    t.integer  "order_id",   limit: 4,                          null: false
    t.decimal  "budget",               precision: 10, scale: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_orders", ["order_id"], name: "index_task_orders_on_order_id", using: :btree
  add_index "task_orders", ["task_id"], name: "index_task_orders_on_task_id", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.string   "external_id",      limit: 255,                                         null: false
    t.integer  "user_id",          limit: 4
    t.boolean  "accepted",         limit: 1,                           default: false
    t.boolean  "paid",             limit: 1,                           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "budget",                       precision: 8, scale: 2, default: 0.0
    t.boolean  "review_requested", limit: 1,                           default: false, null: false
    t.boolean  "expenses",         limit: 1,                           default: false
  end

  add_index "tasks", ["external_id"], name: "index_tasks_on_external_id", unique: true, using: :btree
  add_index "tasks", ["user_id"], name: "index_tasks_on_user_id", using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name",               limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "default_commission", limit: 4
    t.integer  "parent_id",          limit: 4,   null: false
  end

  create_table "timesheets", force: :cascade do |t|
    t.integer  "sp_id",           limit: 4, null: false
    t.integer  "user_id",         limit: 4, null: false
    t.datetime "start_timestamp",           null: false
    t.datetime "end_timestamp",             null: false
    t.integer  "in_day",          limit: 4, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "timesheets", ["user_id"], name: "index_timesheets_on_user_id", using: :btree

  create_table "transactions", force: :cascade do |t|
    t.decimal  "total",                    precision: 10, scale: 2, null: false
    t.string   "comment",      limit: 255,                          null: false
    t.integer  "account_id",   limit: 4,                            null: false
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "accrual_date"
    t.string   "old_comment",  limit: 255
  end

  add_index "transactions", ["account_id"], name: "index_transactions_on_account_id", using: :btree
  add_index "transactions", ["comment"], name: "index_transactions_on_comment", using: :btree
  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",       limit: 255,                                        null: false
    t.string   "login",      limit: 255,                                        null: false
    t.integer  "team_id",    limit: 4,                                          null: false
    t.decimal  "daily_rate",             precision: 5, scale: 2,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id",    limit: 4,                                          null: false
    t.boolean  "active",     limit: 1,                           default: true
  end

  add_index "users", ["role_id"], name: "index_users_on_role_id", using: :btree
  add_index "users", ["team_id"], name: "index_users_on_team_id", using: :btree

  add_foreign_key "orders", "invoices"
  add_foreign_key "orders", "invoices"
  add_foreign_key "orders", "orders", column: "parent_id"
  add_foreign_key "orders", "orders", column: "parent_id"
  add_foreign_key "orders", "teams"
  add_foreign_key "orders", "teams"
  add_foreign_key "task_orders", "orders"
  add_foreign_key "task_orders", "orders"
  add_foreign_key "task_orders", "tasks"
  add_foreign_key "task_orders", "tasks"
  add_foreign_key "tasks", "users"
  add_foreign_key "tasks", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "teams"
end
