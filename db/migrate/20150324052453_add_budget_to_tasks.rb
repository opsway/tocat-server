class AddBudgetToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :budget, :decimal, precision: 8, scale: 2, default: 0.0
  end
end
