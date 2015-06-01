class RemoveClientFronInvoices < ActiveRecord::Migration
  def change
    remove_column :invoices, :client, :string

  end
end
