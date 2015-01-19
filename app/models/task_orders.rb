class TaskOrders < ActiveRecord::Base
  validates :task_id, presence: true
  validates :order_id, presence: true
  validates :budget,
            numericality: { greater_than: 0 },
            presence: true

  belongs_to :order
  belongs_to :task

  before_save :check_free_budget
  before_save :decrease_free_budget
  after_destroy :increase_free_budget

  private

  def check_free_budget
    if self.budget > self.order.free_budget
      errors[:base] << 'Budget must be lower than free budget from order'
      false
    end
  end

  def decrease_free_budget
    if new_record?
      val = self.order.free_budget - self.budget
      self.order.update_attributes(free_budget: val)
    else
      old_val = self.budget_was
      order.free_budget += old_val
      new_free_budget = order.free_budget - budget
      order.update_attributes(free_budget: new_free_budget)
    end
  end

  def increase_free_budget
    val = self.order.free_budget + self.budget
    self.order.update_attribute(:free_budget, val)
  end
end
