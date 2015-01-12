class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.decimal :total, :null => false
      t.string :comment
      t.integer :account_id, :null => false
      t.integer :user_id, :null => false
      t.timestamps
    end
  end
end
