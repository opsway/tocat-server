class CreateTaskOrders < ActiveRecord::Migration
  def change
    create_table :task_orders do |t|
      t.integer :task_id, :null => false
      t.integer :order_id, :null => false
      t.decimal :budget, :precision => 5, :scale => 2
      t.timestamps
    end
  end
end
