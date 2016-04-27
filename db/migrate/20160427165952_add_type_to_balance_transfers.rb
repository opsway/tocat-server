class AddTypeToBalanceTransfers < ActiveRecord::Migration
  def change
    add_column :balance_transfers, :btype, :string
  end
end
