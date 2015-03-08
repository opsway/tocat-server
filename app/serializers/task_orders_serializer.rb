class TaskOrdersSerializer < ActiveModel::Serializer
  attributes :id, :order_id, :budget

  private

  def budget
    object.budget.to_f
  end
end
