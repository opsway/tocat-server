class AddPolymorphicColumnsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :accountable_id, :integer
    add_column :accounts, :accountable_type, :string
    add_index :accounts, :accountable_id
  end
end
