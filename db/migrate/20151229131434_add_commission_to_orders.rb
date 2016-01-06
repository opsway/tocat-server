class AddCommissionToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :commission, :integer
  end
end
