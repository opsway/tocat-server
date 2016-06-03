class CreateManyToManyPaymentRequestsUsers < ActiveRecord::Migration
  def change
    create_table :payment_requests_users do |t|
      t.references :user
      t.references :payment_request
      t.timestamps null: false
    end
  end
end
