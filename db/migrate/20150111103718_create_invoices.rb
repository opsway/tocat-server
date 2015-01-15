class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.string :client, null: false
      t.string :external_id
      t.boolean :paid, default: false
      t.timestamps
    end
  end
end
