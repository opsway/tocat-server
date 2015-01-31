class ChangeInvoiceClient < ActiveRecord::Migration
  def change
    change_column :invoices, :client, :string, :null => true
    change_column :invoices, :order_id, :string, :null => true

  end
end
