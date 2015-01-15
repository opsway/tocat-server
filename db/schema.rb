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

ActiveRecord::Schema.define(version: 20150115141629) do

  create_table "accounts", force: true do |t|
    t.string   "account_type",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "accountable_id",   null: false
    t.string   "accountable_type", null: false
  end

  add_index "accounts", ["accountable_id"], name: "index_accounts_on_accountable_id", using: :btree

  create_table "invoices", force: true do |t|
    t.string   "client",                      null: false
    t.string   "external_id"
    t.boolean  "paid",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id",                    null: false
  end

  add_index "invoices", ["client"], name: "index_invoices_on_client", using: :btree
  add_index "invoices", ["order_id"], name: "index_invoices_on_order_id", using: :btree

  create_table "orders", force: true do |t|
    t.string   "name",                                                        null: false
    t.text     "description"
    t.boolean  "paid",                                        default: false
    t.integer  "team_id",                                                     null: false
    t.integer  "invoice_id"
    t.decimal  "invoiced_budget",    precision: 10, scale: 2,                 null: false
    t.decimal  "allocatable_budget", precision: 10, scale: 2,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.decimal  "free_budget",        precision: 10, scale: 2,                 null: false
  end

  add_index "orders", ["team_id"], name: "index_orders_on_team_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_orders", force: true do |t|
    t.integer  "task_id",                             null: false
    t.integer  "order_id",                            null: false
    t.decimal  "budget",     precision: 10, scale: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: true do |t|
    t.string   "external_id",                 null: false
    t.integer  "user_id"
    t.boolean  "accepted",    default: false
    t.boolean  "paid",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tasks", ["external_id"], name: "index_tasks_on_external_id", using: :btree
  add_index "tasks", ["user_id"], name: "index_tasks_on_user_id", using: :btree

  create_table "teams", force: true do |t|
    t.string   "name",                 null: false
    t.integer  "balance_account_id"
    t.integer  "gross_profit_account"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: true do |t|
    t.decimal  "total",      precision: 10, scale: 2, null: false
    t.string   "comment",                             null: false
    t.integer  "account_id",                          null: false
    t.integer  "user_id",                             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["comment"], name: "index_transactions_on_comment", using: :btree

  create_table "users", force: true do |t|
    t.string   "name",                                       null: false
    t.string   "login",                                      null: false
    t.integer  "team_id",                                    null: false
    t.decimal  "daily_rate",         precision: 5, scale: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id",                                    null: false
    t.integer  "balance_account_id"
    t.integer  "income_account_id"
  end

end
