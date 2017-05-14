class AddBudgetTransferedToGrowthFundToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :budget_transfered_to_growth_fund, :boolean, default: false
    
    execute("UPDATE orders SET budget_transfered_to_growth_fund=TRUE WHERE updated_at < '2017-03-01' AND (team_id = 7 OR team_id = 8)")
  end
end
