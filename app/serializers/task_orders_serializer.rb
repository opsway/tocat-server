class TaskOrdersSerializer < ActiveModel::Serializer
  attributes :id, :order_id, :budget, :order_name

  private

  def order_name
    object.order.name
  end

  def budget
    object.budget.to_f
  end
end
