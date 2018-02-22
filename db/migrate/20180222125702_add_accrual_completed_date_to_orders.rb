class AddAccrualCompletedDateToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :accrual_completed_date, :date
  end
end
