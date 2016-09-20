class AddPayrollToTransferRequests < ActiveRecord::Migration
  def change
    add_column :transfer_requests, :payroll, :boolean, default: false
  end
end
