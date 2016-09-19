class AddDefaultAccountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_account_id, :integer
  end
end
