class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.integer :balance_account_id, null: false
      t.integer :gross_profit_account, null: false
      t.timestamps
    end
  end
end
