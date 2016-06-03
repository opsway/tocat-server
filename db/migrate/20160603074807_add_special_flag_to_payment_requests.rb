class AddSpecialFlagToPaymentRequests < ActiveRecord::Migration
  def change
    add_column :payment_requests, :special, :boolean, default: false
  end
end
