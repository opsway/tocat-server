class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }
  validate :check_resolver_team, if: Proc.new { |o| o.user_id_changed? && !o.orders.empty? && !o.user_id == nil }

  has_many :task_orders, class_name: 'TaskOrders'
  has_many :orders, through: :task_orders

  after_save :update_balance_accounts, if: Proc.new { |o| (o.paid_changed? || o.accepted_changed?) && user.present?}

  belongs_to :user

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

  def check_resolver_team
    team = orders.first.team
    orders.each do |order|
      if team != order.team
        errors[:base] << "Orders team are not equal. Please, contact your administrator."
      end
    end
    if user.team != team
      errors[:base] << "Task resolver is from different team than order"
    end
  end

  def update_balance_accounts
    if accepted && paid
      binding.pry
      user.balance_account += bugdet
      user.team.balance_account += budget
    end
  end
end
