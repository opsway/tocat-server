class CreateTransferRequests < ActiveRecord::Migration
  def change
    create_table :transfer_requests do |t|
      t.integer :source_id, index: true
      t.integer :target_id, index: true
      t.integer :balance_transfer_id
      t.string :description
      t.float :total
      t.string :state
      t.add_foreign_key :users, column: :source_id
      t.add_foreign_key :users, column: :target_id
      t.add_foreign_key :balance_transfers
      t.timestamps null: false
    end
  end
end
