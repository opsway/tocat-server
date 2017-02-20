class ChangeTotalTypeInTransactions < ActiveRecord::Migration
  def self.up
    change_column :transactions, :total, :decimal, null: false, :precision => 15, :scale => 2
  end

  def self.down
    change_column :transactions, :total, :decimal, null: false
  end
end
