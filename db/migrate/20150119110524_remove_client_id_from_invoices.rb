class RemoveClientIdFromInvoices < ActiveRecord::Migration
  def change
    remove_column :invoices, :order_id, :integer
  end
end
