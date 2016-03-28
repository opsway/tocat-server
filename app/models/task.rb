require 'will_paginate/array'
class Task < ActiveRecord::Base
  include PublicActivity::Common
  validates :external_id,  presence: { message: "Missing external task ID" }, uniqueness: { message: "External ID is already used" }
  validate :resolver_must_be_in_task_team, if: proc { |o| o.user_id_changed? && !o.user_id.nil? }
  validate :check_if_order_completed, if: proc { |o| o.task_orders.any? }
  validate :orders_in_the_same_team, if: proc { |o| o.task_orders.any? }
  validate :expense_should_not_have_resolver
  validate :manager_can_not_be_resolver, if: proc { |t| t.resolver.present? }

  has_many :task_orders,
           class_name: 'TaskOrders',
           after_add: [:increase_budget],
           before_remove: [:decrease_budget]

  has_many :orders, through: :task_orders

  before_save :handle_balance_after_changing_resolver, if: proc { |o| o.paid && o.accepted && o.user_id_changed? }
  before_save :handle_balance_after_changing_paid_status, if: proc { |o| (o.accepted_changed? || o.paid_changed?) && o.user_id.present? }
  before_save :handle_balance_after_changing_budget, if: proc { |o| o.paid && o.accepted && o.budget_changed? }


  belongs_to :user

  accepts_nested_attributes_for :task_orders, reject_if: :all_blank, allow_destroy: true
  validates_associated :task_orders
  validate :validate_unique_task_orders
  scoped_search on: :external_id
  scoped_search on: :budget, only_explicit: true
  scoped_search on: [:accepted, :paid, :review_requested], only_explicit: true, ext_method: :boolean_find
  scoped_search in: :user, on: :id, rename: :resolver, only_explicit: true
  scoped_search in: :orders, on: :id, rename: :order, only_explicit: true
  
  scope :with_expenses, ->{ where(expenses: true) }
  scope :without_expenses, -> { where(expenses: false) }
  scope :with_resolver, -> { where.not(user: nil) }
  scope :without_resolver, -> { where(user: nil) }

  alias_method :resolver, :user

  def self.boolean_find(key, operator, value)
    { conditions: sanitize_sql_for_conditions(["tasks.#{key} #{operator} ?", value.to_s.to_bool]) }
  end

  def handle_paid(paid)
    return self.update_attributes!(paid: false) unless paid
    self.update_attributes!(paid: can_be_paid?)
  end

  def team
    order_with_team = orders.reload.detect { |o| o.team.present? }
    order_with_team.team if order_with_team
  end

  def external_url
    #Settings.external_tracker.url + external_id
  end

  def recalculate_paid_status!
    self.update_attributes!(paid: can_be_paid?)
  end

  private

  def can_be_paid?
    orders.any? && orders.all?(&:paid?)
  end

  def check_if_order_completed
    return if review_requested_changed?
    errors[:base] << 'Completed order is used in budgets, can not update task' if orders.any?(&:completed?)
  end

  def expense_should_not_have_resolver
    return unless expenses && resolver.present?
    if expenses_changed?
      errors[:expenses] << 'Please remove Resolver first to setup Expense flag.'
    else
      errors[:resolver] << 'You can not setup Resolver for issue that is Expense'
    end
  end

  def manager_can_not_be_resolver
    errors[:resolver] << 'Manager can not be set as a resolver' if resolver.manager?
  end

  def increase_budget(task_order)
    self.update_attributes(budget: self.budget += task_order.budget)
  end

  def decrease_budget(task_order)
    self.update_attributes(budget: self.budget -= task_order.budget)
  end

  def validate_unique_task_orders
    validate_uniqueness_of_in_memory(task_orders, [:order_id, :task_id], 'Duplicate Budgets.')
  end

  def handle_balance_after_changing_paid_status
    self.transaction do
      if accepted && paid
        create_transactions(user, team, budget, "Accepted and paid issue #{self.external_id}")
      elsif accepted_was == true && paid_was == true
        create_transactions(user, team, -budget, "Reopening issue #{self.external_id}")
      end
    end
  end

  def handle_balance_after_changing_budget
    self.transaction do
      if budget_was != nil && budget == 0 && user.present?
        create_transactions(user, user.team, -budget_was, "Reopening issue #{self.external_id}")
      end
    end
  end

  def handle_balance_after_changing_resolver
    self.transaction do
      if user_id_was != nil
        old_user = User.find(user_id_was)
        create_transactions(old_user, team, -budget, "Reopening issue #{self.external_id}")
      end
      if user_id != nil
        create_transactions(user, team, budget, "Accepted and paid issue #{self.external_id}")
      end
    end
  end

  def create_transactions(owner, team, total, message)
    owner_balance_was = owner.balance_account.balance
    team_balance_was = team.balance_account.balance
    team_income_was = team.income_account.balance

    owner.balance_account.transactions.create!(total: total, comment: message, user_id: owner.id)
    team.balance_account.transactions.create!(total: total, comment: message, user_id: owner.id)
    team.income_account.transactions.create!(total: total, comment: message, user_id: owner.id)

    create_balance_update_activity(
      type: 'balance', recipient: owner,
      old: owner_balance_was, new: owner.balance_account.balance,
      message: message)
    create_balance_update_activity(
      type: 'balance', recipient: team,
      old: team_balance_was, new: team.balance_account.balance,
      message: message)
    create_balance_update_activity(
      type: 'payment', recipient: team,
      old: team_income_was, new: team.income_account.balance,
      message: message)
  end

  def create_balance_update_activity(type:, old:, new:, recipient:, message:)
    recipient.create_activity(
      :balance_update,
      parameters: {
        type: type,
        was: old,
        new: new,
        message: message
      },
      recipient: recipient,
      owner: User.current_user)
  end

  def resolver_must_be_in_task_team
    errors[:base] << 'Task resolver is from different team than order' if resolver && team && resolver.team != team
  end

  def orders_in_the_same_team
    orders_teams = orders.map(&:team).uniq
    errors[:base] << 'Orders are created for different teams' if orders_teams.size > 1
  end
end


module ActiveRecord
  class Base
    def validate_uniqueness_of_in_memory(collection, attrs, message)
      hashes = collection.inject({}) do |hash, record|
        key = attrs.map { |a| record.send(a).to_s }.join
        if key.blank? || record.marked_for_destruction?
          key = record.object_id
        end
        hash[key] ||= record
        hash
      end
      raise(message) if collection.length > hashes.length
    end
  end
end
