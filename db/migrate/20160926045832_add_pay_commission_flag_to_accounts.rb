class AddPayCommissionFlagToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :pay_comission, :boolean, default: true
  end
end
