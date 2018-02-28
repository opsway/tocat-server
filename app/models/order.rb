class Order < ActiveRecord::Base
  include PublicActivity::Common

  INTERNAL_ORDER_COMMISSION = 0

  validates :name, presence: { message: "Order name can not be empty" }
  validates :team, presence: { message: "Team does not exists" }
  validates :allocatable_budget, presence: { message: "Allocatable budget is missing" }
  validates :invoiced_budget, presence: { message: "Invoiced budget is missing" }
  validate :existence_of_invoice, if: :invoice_id?
  validate :non_existence_of_invoice_in_internal_orders
  validate :non_complete_on_internal_remove, if: :internal_order_changed?
  validate :current_user_is_in_team_for_internal, if: :internal_order_changed?

  validates_numericality_of :invoiced_budget,
                            greater_than: 0,
                            message: "Invoiced budget should be greater than 0"
  # validates_numericality_of :free_budget,
  #                           greater_than: 0,
  #                           message: "Unexpected error: 'Free budget should be greater than 0'. Please contact administrator"
  validates_numericality_of :allocatable_budget,
                            greater_than_or_equal_to: 0,
                            message: "Allocatable should be positive number"

  validates_numericality_of :commission,
                            greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100,
                            message: "Commission should be positive number between 0-100",
                            only_integer: true,
                            allow_nil: false
  validate :check_complete_change_commission, if: :commission_changed?
  validate :parent_has_no_parent, if: 'parent.present?'
  validate :parent_has_enough_free_budget, if: 'parent.present?'
  validate :parent_has_different_team, if: 'parent.present?'

  scoped_search on: [:name, :description, :invoiced_budget, :allocatable_budget, :free_budget, :paid, :completed, :internal_order]
  scoped_search in: :team, on: :name, rename: :team, only_explicit: true
  scoped_search on: :parent_id, only_explicit: true
  scoped_search on: :invoice_id, only_explicit: true
  scoped_search on: :id, only_explicit: true

  validate :check_budgets
  validate :check_if_team_exists
  validate :sub_order_team
  validate :check_inheritance
  validate :disallow_internal_for_suborders, if: :internal_order_changed?
  #validate :cant_complete_internal_order_with_free_budget_left, if: :completed_changed?
  validate :must_be_paid_when_completed
  validate :must_have_zoho_project_id_and_accrual_date_when_completed

  before_save :check_budgets_for_sub_order
  after_save :set_paid_for_internal_order, if: :internal_order_changed?

  belongs_to :team
  belongs_to :invoice
  has_many :task_orders, class_name: 'TaskOrders'
  has_many :tasks, through: :task_orders

  has_many :sub_orders, class_name: 'Order', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Order'

  before_save :set_invoiced, if: proc { |o| o.new_record? && o.parent.present? }
  validate :check_internal, if: proc {|o| o.team_id_changed? && o.persisted? }
  before_save :set_free_budget, if: proc { |o| o.new_record? }
  before_destroy :check_if_order_has_tasks
  before_destroy :check_for_suborder
  before_save :check_if_paid, if: proc { |o| o.invoice_id_changed? }
  before_destroy :check_if_paid_before_destroy
  after_destroy :recalculate_parent_free_budget, if: proc { |o| o.parent_id.present? }
  # before_save :check_if_paid_on_budget_update, if: proc { |o| o.invoiced_budget_changed? && !o.internal_order? }
  before_save :check_if_invoice_already_paid, if: proc { |o| o.invoice_id_changed? }
  before_save :check_for_tasks_on_team_change, if: proc { |o| o.team_id_changed? }
  before_save :check_if_suborder, if: proc { |o| o.invoice_id_changed? }
  before_save :paid_from_parent, if: proc { |o| o.parent_id.present? }
  before_save :check_if_allocatable_budget_lt_used, if: proc { |o| o.allocatable_budget_changed? }
  before_save :recalculate_free_budget, if: proc { |o| o.allocatable_budget_changed? && !o.new_record? }
  after_save :recalculate_parent_free_budget, if: proc { |o| o.allocatable_budget_changed? && !o.new_record? && o.parent.present? }
  after_save :recalculate_parent_free_budget, if: proc { |o| o.invoiced_budget_changed? && !o.new_record? && o.parent.present? }
  before_save :check_for_completed, if: proc { |o| !o.completed_changed? }
  before_save :check_if_suborder_before_change_completed, if: proc { |o| o.completed_changed? }
  before_save :check_if_parent_completed_on_suborder_creation, if: proc { |o| o.new_record? && o.parent_id.present? }
  before_save :handle_completed, if: proc { |o| o.completed_changed? && o.parent_id.nil? }
  before_destroy :check_if_parent_completed, if: proc { |o| o.parent_id.present? }
  #before_save :check_dberrors, if: :completed?
  before_validation :set_paid_flag
  before_validation :set_teams_default_commission, if: proc { |o| o.commission.nil? }
  before_validation :set_internal_from_parent

  def order_transactions
    Transaction.where("comment like 'Order ##{id} was%'")
  end
  def handle_paid(paid)
    self.update_attributes!(paid: paid)
  end

  def recalculate_free_budget!
    recalculate_free_budget_and_save
  end

  def handle_completed
    couch = team.couch
    unless team.manager.present? && User.current_user != couch
      errors[:base] << 'Team does not have active managers and you does not coach of order team!'
      return
    else
      self.transaction do
      unless team.manager.coach?
        team.manager.balance_account.transactions.create! total: invoiced_budget - task_orders.joins(:task).where("tasks.expenses = true").sum(:budget), comment: "Order ##{id} was completed"
      end
      unless team.manager.coach?
        team.manager.balance_account.transactions.create! total: -(invoiced_budget * self.commission_coefficient), comment: "Order ##{id} was completed: Central Office fee"
      end
      unless self.internal_order?
        couch.money_account.transactions.create! total: invoiced_budget, comment: "Order ##{id} was completed"
          unless self.reseller?
          # couch.money_account.transactions.create! total: invoiced_budget, comment: "Order ##{id} was completed"
          #couch.income_account.transactions.create! total: - (invoiced_budget * couch.team.default_commission / 100.00), comment: "Order ##{id} was completed: Central Office fee"
          #TODO
          if Setting.central_office_commission > 0
            Account.find(Setting.central_office_account_id).transactions.create! total: invoiced_budget * Setting.central_office_commission / 100.00,
              comment: "Order ##{id} was completed: Central Office fee"
            couch.money_account.transactions.create! total: - invoiced_budget * Setting.central_office_commission / 100.00,
              comment: "Order ##{id} was completed: Central Office fee"
          end

          if Setting.growth_commission > 0
            Account.find(Setting.growth_fund_account_id).transactions.create! total: invoiced_budget * Setting.growth_commission / 100.00,
              comment: "Order ##{id} was completed: Growth commission"
            couch.money_account.transactions.create! total: - invoiced_budget * Setting.growth_commission / 100.00,
              comment: "Order ##{id} was completed: Growth commission"
          end

          if Setting.finance_commission > 0
            Account.find(Setting.finance_fund_account_id).transactions.create! total: invoiced_budget * Setting.finance_commission / 100.00,
              comment: "Order ##{id} was completed: Finance commission"
            couch.money_account.transactions.create! total: - invoiced_budget * Setting.finance_commission / 100.00,
              comment: "Order ##{id} was completed: Finance commission"
          end
          if Setting.teams_commission > 0
            Account.find(Setting.teams_fund_account_id).transactions.create! total: invoiced_budget * Setting.teams_commission / 100.00,
              comment: "Order ##{id} was completed: Teams commission"
            couch.money_account.transactions.create! total: - invoiced_budget * Setting.teams_commission / 100.00,
              comment: "Order ##{id} was completed: Teams commission"
          end
          if Setting.dividends_commission > 0
            Account.find(Setting.dividends_fund_account_id).transactions.create! total: invoiced_budget * Setting.dividends_commission / 100.00,
              comment: "Order ##{id} was completed: Dividends commission"
            couch.money_account.transactions.create! total: - invoiced_budget * Setting.dividends_commission / 100.00,
              comment: "Order ##{id} was completed: Dividends commission"
          end
          if Setting.coaches_commission > 0
            Account.find(Setting.coaches_fund_account_id).transactions.create! total: invoiced_budget * Setting.coaches_commission / 100.00,
              comment: "Order ##{id} was completed: Coaches commission"
            couch.money_account.transactions.create! total: - invoiced_budget * Setting.coaches_commission / 100.00,
              comment: "Order ##{id} was completed: Coaches commission"
          end
        end
      end
    end
    end
  end

  def handle_complete_tax(team, val, commission)
    team.manager.balance_account.transactions.create! total: val * commission / 100.0, comment: "Order ##{id} was completed: Central Office fee"
    return if parent_id.present?
    if team != team.parent
      team.manager.balance_account.transactions.create! total: -(val * team.default_commission / 100.0), comment: "Order ##{id} was completed: Central Office fee"
      handle_complete_tax(team.parent, val, team.default_commission)
    end
  end


  def handle_uninternal
    self.update_attributes(internal_order: false, paid: false)
    self.sub_orders.update_all(internal_order: false, paid: false)
    self.tasks.each do |task|
      task.handle_paid(false)
      task.create_activity(:paid_update,
                           parameters: {
                             internal: false,
                             old: !task.paid,
                             new: false
                           },
                           owner: User.current_user)
    end
  end

  def commission_coefficient
    commission / 100.0
  end

  def free_budget_except_order(child_order)
    sub_orders_budget = sub_orders.where.not(id: child_order.id)
      .sum(:invoiced_budget)
    tasks_budget = task_orders.sum(:budget)
    allocatable_budget - (sub_orders_budget + tasks_budget)
  end

  def transfer_money_to_growth_fund_from_pacman_and_nfs
    self.transaction do
      couch = team.couch
      couch.money_account.transactions.create! total: -calculation_of_transfer_amount_to_growth_fund,
      comment: "Transfer budget from #{couch.name} to growth fund was completed. Order##{id}"
      Account.find(Setting.growth_fund_account_id).transactions.create! total: calculation_of_transfer_amount_to_growth_fund,
      comment: "Transfer budget from #{couch.name} to growth fund was completed. Order##{id}"

      update_column(:budget_transfered_to_growth_fund, true)
    end
  end

  private

  def calculation_of_transfer_amount_to_growth_fund
    growth_c = invoiced_budget * Setting.growth_commission / 100.00
    central_office_c = invoiced_budget * Setting.central_office_commission / 100.00
    finance_c = invoiced_budget * Setting.finance_commission / 100.00
    teams_c = invoiced_budget * Setting.teams_commission / 100.00
    dividends_c = invoiced_budget * Setting.dividends_commission / 100.00
    coaches_c = invoiced_budget * Setting.coaches_commission / 100.00

    invoiced_budget - (growth_c + central_office_c + finance_c + teams_c + dividends_c + coaches_c)
  end

  def set_invoiced
    self.invoiced_budget = allocatable_budget
  end

  def existence_of_invoice
    errors[:base] << 'Invoice does not exist' unless invoice.present?
  end

  def check_if_parent_completed
    if parent.try(:completed)
      errors[:base] << 'Can not delete suborder when parent order completed'
      false
    end
  end

  def check_if_parent_completed_on_suborder_creation
    if parent.completed?
      errors[:base] << 'Can not create suborder from completed order'
      false
    end
  end
  def non_existence_of_invoice_in_internal_orders
    if invoice_id.present? && internal_order
      errors[:base] << "Internal order can't have invoice"
      false
    end
  end

  def check_if_suborder_before_change_completed
    if parent_id.present?
      errors[:base] << 'Can not un-complete suborder' unless completed
      false
    end
  end

  def check_for_completed
    if completed_was
      errors[:base] << 'Can not modify completed order'
      false
    else
      true
    end
  end

  def recalculate_parent_free_budget
    parent.recalculate_free_budget!
  end

  def recalculate_free_budget
    val = task_orders.sum(:budget)
    val += sub_orders.sum(:invoiced_budget)
    self.free_budget = allocatable_budget - val
  end

  def recalculate_free_budget_and_save
    val = task_orders.sum(:budget)
    val += sub_orders.sum(:invoiced_budget)
    self.update_attributes!(free_budget: allocatable_budget - val)
  end

  def check_if_allocatable_budget_lt_used
    used_budget = task_orders.sum(:budget)
    used_budget += sub_orders.sum(:allocatable_budget)
    if allocatable_budget < used_budget
      errors[:base] << 'Allocatable bugdet is less than already used from order'
      false
    end
  end

  def paid_from_parent
    self.paid = parent.paid
    true
  end

  def check_if_suborder
    if parent.present?
      errors[:base] << 'Suborder can not be invoiced'
      false
    end
  end

  def check_for_tasks_on_team_change
    if tasks.present?
      errors[:base] << 'Can not change order team - order is used in tasks'
      false
    end
  end

  def check_if_invoice_already_paid
    if invoice.present?
      if invoice.paid
        errors[:base] << 'Invoice is already paid, can not use it for new order'
        false
      end
    end
  end

  # def check_if_paid_on_budget_update
  #   if paid && parent_id.nil?
  #     errors[:base] << 'Order is already paid, can not update invoiced budget'
  #     return false
  #   end
  # end

  def check_if_paid_before_destroy
    if paid
      errors[:base] << 'Can not delete already paid invoice'
      return false
    end
  end

  def check_if_paid
    if paid
      if invoice_id.nil?
        errors[:base] << 'Order is already paid, can not unlink it from invoice'
      else
        errors[:base] << 'Order is already paid, can not change invoice'
      end
      false
    end
  end

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

  def sub_order_team
    if new_record? && parent.present?
      if team == parent.team
        errors[:base] << 'Suborder can not be created for the same team as parent order'
      end
    end
  end

  def check_budgets_for_sub_order
    if new_record? && parent.present?
      if invoiced_budget > parent.free_budget
        errors[:base] << 'Suborder can not be invoiced more than parent free budget'
        return false
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

  def check_dberrors
    if DbError.any_error?
      errors[:base] << 'TOCAT Self-check has errors, please check Status page'
      false
    end
  end
  def check_budgets
    if allocatable_budget.present? && invoiced_budget.present?
      if allocatable_budget > invoiced_budget
        errors[:base] << "Allocatable budget is greater than invoiced budget"
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
    elsif allocatable_budget_changed?
      self.free_budget = allocatable_budget
    end
  end

  def check_complete_change_commission
    if completed?
      errors.add(:commission,  "can't change commission for completed orders")
      false
    end
  end

  def non_complete_on_internal_remove
    if completed? && !internal_order
      errors.add(:base,  "Can't remove internal_order flag for completed orders")
      false
    end
  end

  def set_paid_for_internal_order
    if self.internal_order
      self.sub_orders.find_each do |suborder|
        suborder.internal_order = true
        suborder.paid = true
        suborder.save
      end
      self.paid = true
      self.tasks.each do |task|
        task.handle_paid(true)
        p "##{task.id} - #{task.paid}"
        task.create_activity(:paid_update,
                             parameters: {
                               internal_order: true,
                               old: !task.paid,
                               new: true
                             },
                             owner: User.current_user)
      end
    end
  end

  def disallow_internal_for_suborders
    if internal_order? and parent_id.present? and !parent.internal_order?
      errors.add(:base, "Can't set internal_order flag to suborder")
      false
    end
  end

  def set_paid_flag
    if internal_order? || (parent.present? && parent.paid?)
      self.paid = true
    end
  end

  def set_internal_from_parent
    if parent.present? && parent.internal_order?
      self.internal_order = true
    end
  end

  def set_teams_default_commission
    self.commission ||= team.try :default_commission
  end

  def parent_has_no_parent
    errors[:parent] << 'Parent must not have parent' if parent && parent.parent.present?
  end

  def parent_has_enough_free_budget
    if parent && parent.free_budget_except_order(self) < invoiced_budget
      errors[:parent] << 'Suborder can not be invoiced more than parent free budget'
    end
  end

  def must_be_paid_when_completed
    errors[:paid] << 'Completed order must be paid' if completed? && !paid?
  end

  def must_have_zoho_project_id_and_accrual_date_when_completed
    if completed? && !self.internal_order?
      if !zohobooks_project_id.present? && !accrual_completed_date.blank?
        errors[:zohobooks_project_id] << 'Before Complete non internal order must have ZohoBooks Project ID'
      elsif zohobooks_project_id.present? && accrual_completed_date.blank?
        errors[:accrual_completed_date] << 'Before Complete non internal order must have Accrual Completed Date'
      elsif !zohobooks_project_id.present? && accrual_completed_date.blank?
        errors[:empty_fields] << 'Before complete, non internal order must have ZohoBooks Project ID and Accrual Completed Date'
      end
    end
  end

  def parent_has_different_team
    errors[:team] << 'Suborder can not have the same team as the parent' if team == parent.team
  end
  def check_internal
    errors[:team] << "Order can't change team if it is 'internal'" if self.internal_order?
  end
  def current_user_is_in_team_for_internal
    if internal_order?
      errors[:base] << "You are not allowed to set this order as Internal" if !User.current_user.try(:team).try(:all_children).try(:include?, self.team.id) || !User.current_user.try(:coach)
    end
  end
end
