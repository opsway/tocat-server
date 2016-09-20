class AddSourceAndTargetAccountIdToInternalInvoicesAndPayments < ActiveRecord::Migration
  def change
    add_column :payment_requests,  :source_account_id, :integer, index: true
    add_column :transfer_requests, :source_account_id, :integer, index: true
    add_column :transfer_requests, :target_account_id, :integer, index: true
    add_column :balance_transfers, :target_account_id, :integer, index: true
    add_column :balance_transfers, :source_account_id, :integer, index: true
  end
end
