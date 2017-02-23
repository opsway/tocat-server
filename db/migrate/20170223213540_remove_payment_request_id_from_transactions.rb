class RemovePaymentRequestIdFromTransactions < ActiveRecord::Migration
  def change
    remove_column :transactions, :payment_request_id, :integer
  end
end
