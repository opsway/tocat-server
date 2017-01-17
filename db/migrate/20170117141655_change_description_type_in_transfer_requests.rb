class ChangeDescriptionTypeInTransferRequests < ActiveRecord::Migration
  def self.up
    change_column :transfer_requests, :description, :text
  end
 
  def self.down
    change_column :transfer_requests, :description, :string
  end
end
