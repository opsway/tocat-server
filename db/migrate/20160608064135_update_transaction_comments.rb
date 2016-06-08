class UpdateTransactionComments < ActiveRecord::Migration
  def change
    Transaction.where("comment like 'Accepted and paid issue%'").find_each do |t|
      task = Task.find_by_external_id(t.comment.split.last)
      t.comment = "Accepted and paid issue #{task.id}"
      t.save
    end
    Transaction.where("comment like 'Reopening issue%'").find_each do |t|
      task = Task.find_by_external_id(t.comment.split.last)
      t.comment = "Reopening issue #{task.id}"
      t.save
    end
  end
end
