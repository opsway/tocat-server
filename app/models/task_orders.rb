class TaskOrders < ActiveRecord::Base
  validates_presence_of :task_id
  validates_presence_of :order_id
  validates :budget,
            :numericality => { :greater_than => 0 },
            :presence => true

  belongs_to :order
  belongs_to :task

end
