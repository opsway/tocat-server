class ChangeInvoiceClient < ActiveRecord::Migration
  def change
    change_column :invoices, :client, :string, :null => true
    change_column :invoices, :order_id, :string, :null => true if column_exists? :invoices, :order_id

  end
end
