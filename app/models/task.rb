class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }
  validate :check_resolver_team, if: Proc.new { |o| o.user_id_changed? && !o.user_id.nil?}

  has_many :task_orders, class_name: 'TaskOrders'

  has_many :orders, through: :task_orders

  before_save :update_balance_accounts, if: Proc.new { |o| (o.paid_changed? || o.accepted_changed?) && o.user.present?}
  before_save :decrease_accounts_balance, if: Proc.new { |o| o.user_id_changed? && o.user_id.nil?}

  belongs_to :user

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

  def decrease_accounts_balance
    resolver = User.find(user_id_was)
    resolver.balance_account.transactions.create! total: - budget,
                                             comment: "#{self.id} accepted and paid",
                                             user_id: 0
    resolver.team.balance_account.transactions.create! total: - budget,
                                             comment: "#{self.id} accepted and paid",
                                             user_id: 0
  end

  def check_resolver_team
    return true if orders.first.nil?
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

  def update_balance_accounts
    if accepted && paid
      user.balance_account.transactions.create! total: budget,
                                               comment: "#{self.id} accepted and paid",
                                               user_id: 0
      user.team.balance_account.transactions.create! total: budget,
                                               comment: "#{self.id} accepted and paid",
                                               user_id: 0

    end
  end
end
