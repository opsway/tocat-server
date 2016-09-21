class UpdateInternalPayments < ActiveRecord::Migration
  def change
    BalanceTransfer.find_each do |b|
      source_id = Account.where(name: b.source.name, account_type: 'money').first.id
      target_id = Account.where(name: b.target.name, account_type: 'money').first.id
      BalanceTransfer.where(id: b.id).update_all(source_id: source_id, target_id: target_id)
    end
  end
end
