class AddReviewFieldToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :review_requested, :boolean, null: false, default: false
  end
end
