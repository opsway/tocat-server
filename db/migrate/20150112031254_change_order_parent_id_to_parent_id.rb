class ChangeOrderParentIdToParentId < ActiveRecord::Migration
  def change
    remove_column :orders, :parent_order_id, :integer
    add_column :orders, :parent_id, :integer
  end
end
