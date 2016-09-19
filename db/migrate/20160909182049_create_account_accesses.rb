class CreateAccountAccesses < ActiveRecord::Migration
  def change
    create_table :account_accesses do |t|
      t.references :account
      t.references :user

      t.timestamps null: false
    end
  end
end
