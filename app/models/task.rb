require 'will_paginate/array'
class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }
  validate :check_resolver_team, if: Proc.new { |o| o.user_id_changed? && !o.user_id.nil? }

  has_many :task_orders,
           class_name: 'TaskOrders',
           before_add: :reject_budget_change_if_task_accepted_and_paid,
           after_add: [ :handle_invoice_paid_status, :increase_budget ],
           before_remove: :decrease_budget

  has_many :orders, through: :task_orders

  before_save :handle_balance_after_changing_resolver, if: Proc.new { |o| o.paid && o.accepted && o.user_id_changed? }
  before_save :handle_balance_after_changing_paid_status, if: Proc.new { |o| (o.accepted_changed? || o.paid_changed?) && o.user_id.present? }
  before_save :handle_balance_after_changing_budget, if: Proc.new { |o| o.paid && o.accepted && o.budget_changed? }


  belongs_to :user

  accepts_nested_attributes_for :task_orders, reject_if: :all_blank, allow_destroy: true
  validates_associated :task_orders
  validate :validate_unique_task_orders
  scoped_search on: :external_id
  scoped_search on: :budget, only_explicit: true
  scoped_search on: [:accepted, :paid], only_explicit: true, ext_method: :boolean_find
  scoped_search in: :user, on: :id, rename: :resolver, only_explicit: true
  scoped_search in: :orders, on: :id, rename: :order, only_explicit: true

  def self.boolean_find(key, operator, value)
    { conditions: sanitize_sql_for_conditions(["tasks.#{key} #{operator} ?", value.to_s.to_bool]) }
  end

  def can_be_paid?
    can_be_paid = true
    orders.each do |order|
      can_be_paid = order.paid unless order.paid
    end
    can_be_paid
  end

  def handle_paid(paid)
    if paid
      if can_be_paid?
        return self.update_attributes(paid: true)
      else
        return false
      end
    else
      return self.update_attributes(paid: false)
    end
  end

  def team
    team = nil
    if task_orders.present?
      task_orders.reload.each { |o| team = o.order.team if team != o.order.team}
    end
    team
  end

  def resolver
    self.user
  end

  def external_url
    #Settings.external_tracker.url + external_id
  end

  private

  def reject_budget_change_if_task_accepted_and_paid(budget)
    if accepted && paid
      raise 'Can not update budget for task that is Accepted and paid'
    end
  end

  def increase_budget(task_order)
    self.update_attributes(budget: self.budget += task_order.budget)
  end

  def decrease_budget(task_order)
    self.update_attributes(budget: self.budget -= task_order.budget)
  end

  def handle_invoice_paid_status(budget)
    if budget.order.present?
      if budget.order.paid
        self.update_attributes!(paid: true)
      end
    end
    true
  end

  def validate_unique_task_orders
    validate_uniqueness_of_in_memory(
      task_orders, [:order_id, :task_id], 'Duplicate Budgets.')

    validate_orders_of_in_memory(
      task_orders, 'Orders are created for different teams')
  end

  def handle_balance_after_changing_paid_status
    self.transaction do
      if accepted && paid
        user.balance_account.transactions.create! total: budget,
                                                 comment: "Accepted and paid issue #{self.external_id}",
                                                 user_id: 0
        user.team.balance_account.transactions.create! total: budget,
                                                 comment: "Accepted and paid issue #{self.external_id}",
                                                 user_id: 0
         user.team.income_account.transactions.create! total: budget,
                                                  comment: "Accepted and paid issue #{self.external_id}",
                                                  user_id: 0
      else
        if accepted_was == true && paid_was == true
          user.balance_account.transactions.create! total: - budget,
                                                   comment: "Reopening issue #{self.external_id}",
                                                   user_id: 0
          user.team.balance_account.transactions.create! total: - budget,
                                                   comment: "Reopening issue #{self.external_id}",
                                                   user_id: 0
          user.team.income_account.transactions.create! total: - budget,
                                                   comment: "Reopening issue #{self.external_id}",
                                                   user_id: 0
        end
      end
    end
  end

  def handle_balance_after_changing_budget
    self.transaction do
      if budget_was != nil && budget == 0
        user.balance_account.transactions.create! total: - budget_was,
                                                  comment: "Reopening issue #{self.external_id}",
                                                  user_id: 0
        user.team.balance_account.transactions.create! total: - budget_was,
                                                       comment: "Reopening issue #{self.external_id}",
                                                       user_id: 0
        user.team.income_account.transactions.create!  total: - budget_was,
                                                       comment: "Reopening issue #{self.external_id}",
                                                       user_id: 0
      end
    end
  end

  def handle_balance_after_changing_resolver
    self.transaction do
      if user_id_was != nil
        old_user = User.find(user_id_was)
        old_user.balance_account.transactions.create! total: - budget,
                                                      comment: "Reopening issue #{self.external_id}",
                                                      user_id: 0
        old_user.team.balance_account.transactions.create! total: - budget,
                                                           comment: "Reopening issue #{self.external_id}",
                                                           user_id: 0
        old_user.team.income_account.transactions.create!  total: - budget,
                                                           comment: "Reopening issue #{self.external_id}",
                                                           user_id: 0
      end
      if user_id != nil
        user.balance_account.transactions.create! total: budget,
                                                 comment: "Accepted and paid issue #{self.external_id}",
                                                 user_id: 0
        user.team.balance_account.transactions.create! total: budget,
                                                 comment: "Accepted and paid issue #{self.external_id}",
                                                 user_id: 0
        user.team.income_account.transactions.create! total: budget,
                                                 comment: "Accepted and paid issue #{self.external_id}",
                                                 user_id: 0
      end
    end
  end

  def check_resolver_team
    return true if orders.empty?
    team = orders.first.team
    orders.each do |order|
      if team != order.team
        errors[:base] << "Task resolver is from different team than order"
      end
    end
    if user.team != team
      errors[:base] << "Task resolver is from different team than order"
    end
  end
end



module ActiveRecord
  class Base
    def validate_uniqueness_of_in_memory(collection, attrs, message)
      hashes = collection.inject({}) do |hash, record|
        key = attrs.map {|a| record.send(a).to_s }.join
        if key.blank? || record.marked_for_destruction?
          key = record.object_id
        end
        hash[key] = record unless hash[key]
        hash
      end
      if collection.length > hashes.length
        raise message
      end
    end

    def validate_orders_of_in_memory(collection, message)
      teams = []
      collection.each { |r| teams << r.order.team if r.order.present? }
      if teams.uniq.length > 1
        collection.first.errors[:base] << message
      end
    end
  end
end
