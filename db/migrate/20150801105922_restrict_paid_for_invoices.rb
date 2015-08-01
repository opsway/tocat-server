class RestrictPaidForInvoices < ActiveRecord::Migration
  def change
    change_column :invoices, :paid, :boolean, default: false, null: false
  end
end
