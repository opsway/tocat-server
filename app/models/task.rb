class Task < ActiveRecord::Base
  validates :external_id, presence: true

  has_many :task_orders, class_name: 'TaskOrders'
  has_many :orders, through: :task_orders
  
  belongs_to :user
end
