class AddForeignKeys < ActiveRecord::Migration
  def change
    add_foreign_key :orders, :teams
    add_foreign_key :orders, :invoices
    add_foreign_key :orders, :orders, column: :parent_id
    add_foreign_key :task_orders, :orders
    add_foreign_key :task_orders, :tasks
    add_foreign_key :tasks, :users
    add_foreign_key :transactions, :accounts
    add_foreign_key :transactions, :users
    add_foreign_key :users, :teams
    add_foreign_key :users, :roles
  end
end
