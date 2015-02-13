class Order < ActiveRecord::Base
  validates :name, presence: { message: "Order name can not be empty" }
  validates :team_id, presence: true
  validates_numericality_of :invoiced_budget,
                            greater_than: 0,
                            message: "Invoiced budget should be greater or equal to 0"
  validates_numericality_of :allocatable_budget,
                            greater_than_or_equal_to: 0,
                            message: "Allocatable should be more than zero"
  validates_presence_of :invoiced_budget
  validates_presence_of :allocatable_budget

  validate :check_budgets
  validate :check_if_team_exists
  validate :sub_order_team
  validate :check_inheritance
  validate :check_budgets_for_sub_order
  validate :check_sub_order_after_update

  belongs_to :team
  belongs_to :invoice
  has_many :task_orders, class_name: 'TaskOrders'
  has_many :tasks, through: :task_orders

  has_many :sub_orders, class_name: 'Order', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Order'

  before_save :set_free_budget
  before_save :decrease_budgets
  before_destroy :increase_budgets
  before_destroy :check_if_order_has_tasks
  before_destroy :check_for_suborder
  #before_save :handle_paid_status, if: Proc.new { |o| o.paid_changed?}

  def handle_paid(paid)
    return self.update_attributes(paid: paid)
  end

  private

  # def handle_paid_status
  #   Order.debug "#{self.id} был вызван."
  #   sub_orders.each { |o| o.update_attributes(paid: paid)}
  #   parent_tasks = []
  #   if parent.present?
  #     parent_tasks = parent.tasks
  #   end
  #   tasks.each do |task|
  #     Order.debug "Таск #{task.id} обновленна. Статус Paid #{paid}"
  #     #next if parent_tasks.include? task
  #     task.update_attributes(paid: paid)
  #   end
  #   Order.debug "Обработка #{self.id} была завершена."
  # end

  def check_for_suborder
    if sub_orders.present?
      errors[:base] << 'You can not delete order when there is a suborder'
      false
    end
  end
  def check_if_order_has_tasks
    if tasks.present?
      errors[:base] << 'You can not delete order that is used in task budgeting'
      false
    end
  end

  def check_sub_order_after_update
    if parent.present?
      if allocatable_budget_changed? || invoiced_budget_changed?
        if allocatable_budget > parent.free_budget || invoiced_budget > parent.free_budget
          errors[:base] << 'Suborder can not be invoiced more than parent free budget'
        end
      end
    end
  end

  def sub_order_team
    if new_record? && parent.present?
      if team == parent.team
        errors[:base] << 'Suborder can not be created for the same team as parent order'
      end
    end
  end

  def increase_budgets
    if parent.present?
      val = parent.allocatable_budget + allocatable_budget
      parent.update_attributes(allocatable_budget: val)
    end
  end

  def decrease_budgets
    if new_record? && parent.present?
      val = parent.allocatable_budget - allocatable_budget
      parent.update_attributes(allocatable_budget: val)
    end
  end

  def check_budgets_for_sub_order
    if new_record? && parent.present?
      if invoiced_budget > parent.free_budget
        errors[:base] << 'Suborder can not be invoiced more than parent free budget'
      end
    end
  end

  def check_inheritance
    if new_record? && parent.present?
      if self.parent.parent.present?
        errors[:base] << 'Suborder can not be created from another suborder'
      end
    end
  end

  def check_budgets
    if allocatable_budget.present? && invoiced_budget.present?
      if allocatable_budget > invoiced_budget
        errors[:base] << "Allocatable budget should be less or equal"
      end
    end
  end

  def check_if_team_exists
    if team_id.present?
      errors[:base] << 'Team does not exists' unless Team.exists?(id: team_id)
    end
  end

  def set_free_budget
    if new_record?
      if parent
        val = parent.free_budget - invoiced_budget
        parent.update_attributes(free_budget: val)
      end
      self.free_budget = allocatable_budget
    elsif invoiced_budget_changed?
      if parent
        val = parent.free_budget - invoiced_budget
        parent.update_attributes(free_budget: val)
      end
    end
  end
end
