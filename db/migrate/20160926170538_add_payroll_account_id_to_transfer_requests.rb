class AddPayrollAccountIdToTransferRequests < ActiveRecord::Migration
  def change
    add_column :transfer_requests, :payroll_account_id, :integer
  end
end
