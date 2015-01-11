class Task < ActiveRecord::Base
  validates_presence_of :external_id
  has_many :task_orders, :class_name => 'TaskOrders'
  has_many :orders, through: :task_orders

end
