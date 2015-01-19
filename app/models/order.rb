class Order < ActiveRecord::Base
  validates :name, presence: { message: "Order name can not be empty" }
  validates :team_id, presence: true
  validates_numericality_of :invoiced_budget,
                            :greater_than => 0,
                            :message => "Invoiced budget should be less or equal"
  validates_numericality_of :allocatable_budget,
                            :greater_than => 0,
                            :message => "Allocatable budget should be less or equal"
  validates_presence_of :invoiced_budget
  validates_presence_of :allocatable_budget

  validate :check_budgets
  validate :check_if_team_exists

  belongs_to :team
  has_many :invoices
  has_many :task_orders, class_name: 'TaskOrders'
  has_many :tasks, through: :task_orders

  has_many :sub_orders, class_name: 'Order', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Order'

  before_save :set_free_budget

  private

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
      binding.pry
      if parent
        val = parent.free_budget - invoiced_budget
        parent.update_attributes(free_budget: val)
      end
      self.free_budget = invoiced_budget - allocatable_budget
    elsif invoiced_budget_changed?
      binding.pry
      if parent
        val = parent.free_budget - invoiced_budget
        parent.update_attributes(free_budget: val)
      end
    end
  end
end
