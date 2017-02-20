class AddPaymentRequestIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :payment_request_id, :integer
  end
end
