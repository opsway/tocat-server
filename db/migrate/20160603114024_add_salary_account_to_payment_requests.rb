class AddSalaryAccountToPaymentRequests < ActiveRecord::Migration
  def change
    add_column :payment_requests, :salary_account_id, :integer
  end
end
