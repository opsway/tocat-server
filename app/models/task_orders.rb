class TaskOrders < ActiveRecord::Base
  validates :task_id, presence: true
  validates :order_id, presence: true
  validates :budget,
            numericality: { greater_than: 0 },
            presence: true

  belongs_to :order
  belongs_to :task
end
