class AddResellerToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :reseller, :boolean, default: false
  end
end
