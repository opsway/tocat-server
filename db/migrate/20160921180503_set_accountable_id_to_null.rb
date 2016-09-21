class SetAccountableIdToNull < ActiveRecord::Migration
  def change
     change_column :accounts, :accountable_id, :integer, default: 0
     change_column :accounts, :accountable_type, :string, default: ''
  end
end
