class AddTransactionAccountIdToSettings < ActiveRecord::Migration
  def change
    Setting.create name: 'transaction_account_id', value: Account.commission_user.money_account.id
  end
end
