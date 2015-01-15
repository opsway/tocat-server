class ChangeUserAccounts < ActiveRecord::Migration
  def change
    remove_column :users, :balance_account, :integer
    remove_column :users, :income_account, :integer
    add_column :users, :balance_account_id, :integer
    add_column :users, :income_account_id, :integer
  end
end
