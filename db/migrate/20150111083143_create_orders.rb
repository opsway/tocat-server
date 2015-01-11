class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :name, :null => false
      t.text :description
      t.boolean :paid, :default => false
      t.integer :parent_order_id
      t.integer :team_id, :null => false
      t.integer :invoice_id
      t.decimal :invoiced_budget, :precision => 8, :scale => 2
      t.decimal :allocatable_budget, :precision => 8, :scale => 2
      t.timestamps
    end
  end
end
