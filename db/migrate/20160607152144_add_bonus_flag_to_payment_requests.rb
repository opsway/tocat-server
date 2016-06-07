class AddBonusFlagToPaymentRequests < ActiveRecord::Migration
  def change
    add_column :payment_requests, :bonus, :boolean, default: false
  end
end
