class TaskOrders < ActiveRecord::Base
  validates :task_id, presence: true
  validates :order_id, presence: true
  validates :budget,
           numericality: { greater_than: 0 },
           presence: true
  validate :check_resolver_team_after_budget_creation
  validate :resolver_presence

  validates_uniqueness_of :task_id, :scope => [:order_id]
  validates_uniqueness_of :order_id, :scope => [:task_id]

  belongs_to :order
  belongs_to :task

  before_save :check_free_budget
  before_save :decrease_free_budget
  before_destroy :increase_free_budget

  private

  def resolver_presence
    return true if task.team.nil?
    unless task.team == order.team
      errors[:base] << "Orders are created for different teams"
    end
  end

  def check_resolver_team_after_budget_creation
    return true unless task.user.present?
    if task.user.team != order.team
      errors[:base] << "Task resolver is from different team than order"
    end
  end

  def check_free_budget
    if self.budget > self.order.free_budget
      errors[:base] << 'You can not assign more budget than is available on order'
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
