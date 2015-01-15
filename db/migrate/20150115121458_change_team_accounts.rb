class ChangeTeamAccounts < ActiveRecord::Migration
  def change
    change_column :teams,
                  :balance_account_id,
                  :integer,
                  null: true
    change_column :teams,
                  :gross_profit_account,
                  :integer,
                  null: true
  end
end
