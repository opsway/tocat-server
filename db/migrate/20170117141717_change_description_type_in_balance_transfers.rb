class ChangeDescriptionTypeInBalanceTransfers < ActiveRecord::Migration
  def self.up
    change_column :balance_transfers, :description, :text
  end
 
  def self.down
    change_column :balance_transfers, :description, :string
  end
end
