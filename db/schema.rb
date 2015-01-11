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

ActiveRecord::Schema.define(version: 20150111105857) do

  create_table "invoices", force: true do |t|
    t.string   "client",                      null: false
    t.string   "external_id"
    t.boolean  "paid",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
  end

  create_table "orders", force: true do |t|
    t.string   "name",                                                       null: false
    t.text     "description"
    t.boolean  "paid",                                       default: false
    t.integer  "parent_order_id"
    t.integer  "team_id",                                                    null: false
    t.integer  "invoice_id"
    t.decimal  "invoiced_budget",    precision: 8, scale: 2
    t.decimal  "allocatable_budget", precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_orders", force: true do |t|
    t.integer  "task_id",                            null: false
    t.integer  "order_id",                           null: false
    t.decimal  "budget",     precision: 5, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", force: true do |t|
    t.string   "external_id"
    t.integer  "user_id"
    t.boolean  "accepted",    default: false
    t.boolean  "paid",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", force: true do |t|
    t.string   "name",                 null: false
    t.integer  "balance_account_id",   null: false
    t.integer  "gross_profit_account", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
