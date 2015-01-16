class RemoveUnnecessaryColumns < ActiveRecord::Migration
  def change
    remove_column :teams, :gross_profit_account, :integer
    remove_column :teams, :balance_account_id, :integer
    remove_column :users, :income_account_id, :integer
    remove_column :users, :balance_account_id, :integer
  end
end
