class CanPayWithdrawInvoicesFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :can_pay_withdraw_invoices, :boolean, default: false
    
    execute("UPDATE users SET can_pay_withdraw_invoices=TRUE WHERE coach=TRUE AND active=TRUE")
  end
end
