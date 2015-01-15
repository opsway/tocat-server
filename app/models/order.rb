class Order < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :team_id
  validates :invoiced_budget,
              numericality: { greater_than: 0 },
              presence: true
  validates :allocatable_budget,
              numericality: { greater_than: 0 },
              presence: true

  validate :check_budgets
  validate :check_if_team_exists

  belongs_to :team
  has_many :invoices
  has_many :task_orders, class_name: 'TaskOrders'
  has_many :tasks, through: :task_orders

  has_many :sub_orders, class_name: "Order", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Order"

  before_save :set_free_budget

  # attr_accessor   :name,
  #                 :description,
  #                 :paid,
  #                 :team_id,
  #                 :invoice_id,
  #                 :invoiced_budget,
  #                 :allocatable_budget,
  #                 :parent_id



  private

  def check_budgets
    if allocatable_budget.present? and invoiced_budget.present?
      if allocatable_budget > invoiced_budget
        errors.add(:allocatable_budget, "must be lower than Invoiced Budget")
      end
    end
  end

  def check_if_team_exists
    if team_id.present?
      errors.add(:team_id, "should exists") unless Team.exists?(id: team_id)
    end
  end

  def set_free_budget
    self.free_budget = self.invoiced_budget - self.allocatable_budget
  end
end
