class CreatePaymentRequests < ActiveRecord::Migration
  def change
    create_table :payment_requests do |t|
      t.integer :target_id
      t.integer :source_id
      t.text :description
      t.float :total
      t.string :currency
      t.string :status

      t.timestamps null: false
    end
  end
end
