class IndexesAndFixes < ActiveRecord::Migration
  def change
    remove_index :tasks, column: :external_id if index_exists?(:tasks, :external_id)
    remove_index :invoices, column: :external_id if index_exists?(:invoices, :external_id)
    add_index(:tasks, [:external_id], unique: true)
    add_index(:invoices, [:external_id], unique: true)
    add_index(:orders, [:invoice_id])
    add_index(:orders, [:parent_id])
    add_index(:task_orders, [:task_id])
    add_index(:task_orders, [:order_id])
    add_index(:timesheets, [:user_id])
    add_index(:transactions, [:account_id])
    add_index(:transactions, [:user_id])
    add_index(:users, [:team_id])
    add_index(:users, [:role_id])
    remove_column :invoices, :order_id, :integer



  end
end
