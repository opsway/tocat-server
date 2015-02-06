class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }
  validate :check_resolver_team, if: Proc.new { |o| o.user_id_changed? }

  has_many :task_orders, class_name: 'TaskOrders', dependent: :destroy
  has_many :orders, through: :task_orders

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
end
