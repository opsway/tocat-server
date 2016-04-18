class CreateBalanceTransfers < ActiveRecord::Migration
  def change
    create_table :balance_transfers do |t|
      t.float :total
      t.integer :source_id
      t.integer :target_id
      t.string :description
      t.datetime :created
      t.integer :source_transaction_id
      t.integer :target_transaction_id
      t.timestamps null: false
    end
  end
end
