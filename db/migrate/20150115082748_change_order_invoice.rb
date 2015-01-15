class ChangeOrderInvoice < ActiveRecord::Migration
  def change
    change_column :orders,
                  :invoice_id,
                  :integer,
                  null: true
  end
end
