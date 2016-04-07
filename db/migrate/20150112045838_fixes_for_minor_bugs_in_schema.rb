class FixesForMinorBugsInSchema < ActiveRecord::Migration
  def change
    #Accounts
    change_column :accounts, :accountable_id, :integer, null: false
    change_column :accounts, :accountable_type, :string, null: false

    #Invoices
    add_index :invoices, :client
    add_index :invoices, :order_id
    change_column :invoices, :order_id, :integer, null: false

    #Orders
    add_index :orders, :team_id
    change_column :orders, :invoice_id, :integer, null: false
    change_column :orders, :invoiced_budget, :decimal,
                  precision: 10, scale: 2, null: false
    change_column :orders, :allocatable_budget, :decimal,
                  precision: 10, scale: 2, null: false
    #Roles
    change_column :roles, :name, :string, null: false

    #Task_Orders
    change_column :task_orders, :budget, :decimal,
                  precision: 10, scale: 2, null: false

    #Tasks
    add_index :tasks, :user_id
    add_index :tasks, :external_id
    change_column :tasks, :external_id, :string, null: false

    #Transactions
    add_index :transactions, :comment
    change_column :transactions, :comment, :string, null: false
    change_column :transactions,
                  :total,
                  :decimal,
                  precision: 10,
                  scale: 2,
                  null: false

    #Users
    change_column :users,
                  :daily_rate,
                  :decimal,
                  precision: 5,
                  scale: 2,
                  null: false
  end
end
