class ChangeRealMoneyToCoach < ActiveRecord::Migration
  def change
    rename_column :users, :real_money, :coach
  end
end
