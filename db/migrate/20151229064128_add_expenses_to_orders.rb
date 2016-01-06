class AddExpensesToOrders < ActiveRecord::Migration
  def change
    add_column :tasks, :expenses, :boolean, default: false
  end
end
