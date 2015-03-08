class TaskOrdersSerializer < ActiveModel::Serializer
  attributes :order_id, :budget, :order_name

  private

  def budget
    object.budget.to_f
  end

  def order_name
    object.order.name
  end
end
