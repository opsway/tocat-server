class TaskOrders < ActiveRecord::Base
  validates :task_id, presence: true
  validates :order_id, presence: true
  validates :budget,
            numericality: { greater_than: 0 },
            presence: true

  belongs_to :order
  belongs_to :task

  before_save :check_free_budget

  private

  def check_free_budget
    if self.budget > self.order.free_budget
      errors[:base] << 'Budget must be lower than free budget from order'
      false
    end
  end
end
