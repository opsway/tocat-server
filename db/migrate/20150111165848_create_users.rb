class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string  :name, null: false
      t.string  :login, null: false
      t.integer :balance_account, null: false
      t.integer :income_account, null: false
      t.integer :team_id, null: false
      t.decimal :daily_rate, null: false
      t.integer :role, null: false
      t.timestamps
    end
  end
end
