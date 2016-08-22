class ChangeDescriptionInTransferRequests < ActiveRecord::Migration
  def change
    change_column :transfer_requests, :description, :text
  end
end
