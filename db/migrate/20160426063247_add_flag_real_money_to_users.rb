class AddFlagRealMoneyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :real_money, :boolean, default: false
  end
end
