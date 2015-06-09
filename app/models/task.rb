require 'will_paginate/array'
class Task < ActiveRecord::Base
  include PublicActivity::Common
  validates :external_id,  presence: { message: "Missing external task ID" }, uniqueness: { message: "External ID is already used" }
  validate :check_resolver_team, if: proc { |o| o.user_id_changed? && !o.user_id.nil? }
  validate :check_if_order_completed, if: proc { |o| o.task_orders.any? }

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
  scoped_search on: [:accepted, :paid], only_explicit: true, ext_method: :boolean_find
  scoped_search in: :user, on: :id, rename: :resolver, only_explicit: true
  scoped_search in: :orders, on: :id, rename: :order, only_explicit: true

  def self.boolean_find(key, operator, value)
    { conditions: sanitize_sql_for_conditions(["tasks.#{key} #{operator} ?", value.to_s.to_bool]) }
  end

  def can_be_paid?
    if task_orders.collect { |r| r.try(:order).try(:paid) }.include? false
      return false
    else
      return true
    end
  end

  def handle_paid(paid)
    if paid
      if can_be_paid?
        return self.update_attributes!(paid: true)
      else
        return false
      end
    else
      return self.update_attributes!(paid: false)
    end
  end

  def team
    team = nil
    if task_orders.present?
      task_orders.reload.each { |o| team = o.order.team if team != o.order.team }
    end
    team
  end

  def resolver
    self.user
  end

  def external_url
    #Settings.external_tracker.url + external_id
  end

  def recalculate_paid_status!
    if task_orders.any?
      self.update_attributes!(paid: can_be_paid?)
    else
      self.update_attributes!(paid: false)
    end
  end

  private

  def check_if_order_completed
    if orders.collect(&:completed).include?(true)
      errors[:base] << 'Completed order is used in budgets, can not update task'
    end
  end

  def increase_budget(task_order)
    self.update_attributes(budget: self.budget += task_order.budget)
  end

  def decrease_budget(task_order)
    self.update_attributes(budget: self.budget -= task_order.budget)
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
        create_transactions(user, team, budget, "Accepted and paid issue #{self.external_id}")
      else
        if accepted_was == true && paid_was == true
          create_transactions(user, team, -budget, "Reopening issue #{self.external_id}")
        end
      end
    end
  end

  def handle_balance_after_changing_budget
    self.transaction do
      if budget_was != nil && budget == 0
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

  def create_transactions(owner, group, total, message)
    owner_balance_was = owner.balance_account.balance
    group_balance_was = group.balance_account.balance
    group_income_was = group.income_account.balance

    owner.balance_account.transactions.create! total: total,
                                               comment: message,
                                               user_id: owner.id
    group.balance_account.transactions.create! total: total,
                                               comment: message,
                                               user_id: owner.id
    group.income_account.transactions.create! total: total,
                                              comment: message,
                                              user_id: owner.id
    owner.create_activity :balance_update,
                                  parameters: { type: 'balance',
                                                was: owner_balance_was,
                                                new: owner.balance_account.balance,
                                                message: message },
                                  recipient: owner.balance_account,
                                  owner: User.current_user
    group.create_activity :balance_update,
                                  parameters: { type: 'balance',
                                                was: group_balance_was,
                                                new: group.balance_account.balance,
                                                message: message },
                                  recipient: group.balance_account,
                                  owner: User.current_user
    group.create_activity :balance_update,
                                  parameters: { type: 'payment',
                                                was: group_income_was,
                                                new: group.income_account.balance,
                                                message: message },
                                  recipient: group.income_account,
                                  owner: User.current_user
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
        errors[:base] << message
      end
    end
  end
end
