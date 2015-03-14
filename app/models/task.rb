class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }
  #validate :check_resolver_team, if: Proc.new { |o| o.user_id_changed? && !o.user_id.nil?}
  validates_associated :task_orders

  has_many :task_orders, class_name: 'TaskOrders', :autosave => true

  has_many :orders, through: :task_orders, :autosave => true

  #before_save :handle_balance_after_changing_resolver, if: Proc.new { |o| o.paid && o.user_id_changed? }
  #before_save :handle_balance_after_changing_paid_status, if: Proc.new { |o| o.paid_changed? && user_id.present? }

  belongs_to :user

  accepts_nested_attributes_for :task_orders, reject_if: :all_blank, allow_destroy: true
  validates_associated :task_orders
  validate :validate_unique_task_orders
  scoped_search on: [:external_id]
  scoped_search :in => :user, :on => :name
  scoped_search :in => :orders, :on => :name




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

  def budget
    budget = BigDecimal 0
    task_orders.each do |record|
      budget += record.budget
    end
    budget
  end

  def external_url
    #Settings.external_tracker.url + external_id
  end

  private

  def validate_unique_task_orders
    validate_uniqueness_of_in_memory(
      task_orders, [:order_id, :task_id], 'Duplicate Budgets.')
  end

  def handle_balance_after_changing_paid_status
    self.transaction do
      if paid
        user.balance_account.transactions.create! total: budget,
                                                 comment: "#{self.external_id} accepted and paid",
                                                 user_id: 0
        user.team.balance_account.transactions.create! total: budget,
                                                 comment: "#{self.external_id} accepted and paid",
                                                 user_id: 0
      else
        user.balance_account.transactions.create! total: - budget,
                                                 comment: "#{self.external_id} unaccepted and unpaid",
                                                 user_id: 0
        user.team.balance_account.transactions.create! total: - budget,
                                                 comment: "#{self.external_id} unaccepted and unpaid",
                                                 user_id: 0
      end
    end
  end

  def handle_balance_after_changing_resolver
    # if user_id_was != nil
    #   old_user = User.find(user_id_was)
    #   old_user.balance_account.transactions.create! total: - budget,
    #                                                 comment: "User was removed from #{id} task",
    #                                                 user_id: 0
    #   old_user.team.balance_account.transactions.create! total: - budget,
    #                                                      comment: "User #{old_user.login} was removed from #{id} task",
    #                                                      user_id: 0
    # end
    # if user_id != nil
    #   user.balance_account.transactions.create! total: budget,
    #                                            comment: "User was setted as resolver for #{id} task",
    #                                            user_id: 0
    #   user.team.balance_account.transactions.create! total: budget,
    #                                            comment: "User #{user.login} was setted as resolver for #{id} task",
    #                                            user_id: 0
    # end
  end

  def check_resolver_team
    return true if orders.first.nil?
  #   team = orders.first.team
  #   orders.each do |order|
  #     if team != order.team
  #       errors[:base] << "Task resolver is from different team than order"
  #     end
  #   end
  #   if user.team != team
  #     errors[:base] << "Task resolver is from different team than order"
  #   end
  end
end



module ActiveRecord
  class Base
    # Validate that the the objects in +collection+ are unique
    # when compared against all their non-blank +attrs+. If not
    # add +message+ to the base errors.
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
  end
end
