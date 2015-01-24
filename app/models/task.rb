class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }

  has_many :task_orders, class_name: 'TaskOrders'
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
    "http://jira.opsway.com/browse/#{external_id}"
  end
end
