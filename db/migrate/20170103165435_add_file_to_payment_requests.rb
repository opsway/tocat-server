class AddFileToPaymentRequests < ActiveRecord::Migration
  def change
    add_column :payment_requests, :file, :string
  end
end
