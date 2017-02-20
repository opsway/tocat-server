class ChangeTotalTypeInPaymentRequests < ActiveRecord::Migration
  def self.up
    change_column :payment_requests, :total, :decimal, :precision => 15, :scale => 2
  end

  def self.down
    change_column :payment_requests, :total, :float
  end
end
