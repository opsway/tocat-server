class BillableStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :billable, :integer, default: 0
  end
end
