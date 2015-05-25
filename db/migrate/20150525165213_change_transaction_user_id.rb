class ChangeTransactionUserId < ActiveRecord::Migration
  def change
    change_column :transactions, :user_id, :integer, :null => true
  end
end
