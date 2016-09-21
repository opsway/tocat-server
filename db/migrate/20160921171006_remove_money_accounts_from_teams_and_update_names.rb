class RemoveMoneyAccountsFromTeamsAndUpdateNames < ActiveRecord::Migration
  def change
    Team.find_each do |team|
      team.money_account.destroy if team.money_account.present?
    end
    Account.find_each do |account|
      if account.accountable.present?
        Account.where(id: account.id).update_all(name: account.accountable.name)
      end
    end
  end
end
