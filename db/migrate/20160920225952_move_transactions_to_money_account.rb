class MoveTransactionsToMoneyAccount < ActiveRecord::Migration
  def change
    start_date = DateTime.parse('1/04/2016')
    User.where(coach: true).find_each do |user|
      user.payroll_account.transactions.where("created_at > ?", start_date).update_all(account_id: user.money_account.id)
    end
  end
end
