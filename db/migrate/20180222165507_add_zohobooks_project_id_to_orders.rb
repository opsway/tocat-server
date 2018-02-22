class AddZohobooksProjectIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :zohobooks_project_id, :string
  end
end
