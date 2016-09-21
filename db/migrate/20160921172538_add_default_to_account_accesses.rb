class AddDefaultToAccountAccesses < ActiveRecord::Migration
  def change
    add_column :account_accesses, :default, :boolean, default: false
  end
end
