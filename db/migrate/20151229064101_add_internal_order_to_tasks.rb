class AddInternalOrderToTasks < ActiveRecord::Migration
  def change
    add_column :orders, :internal_order, :boolean, default: false
  end
end
