class AddFreeBudgetToOrders < ActiveRecord::Migration
  def change
    add_column  :orders, :free_budget,
                :decimal, precision: 10,
                scale: 2, null: false
  end
end
