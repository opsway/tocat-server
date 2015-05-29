class User < ActiveRecord::Base
  include Accounts
  validates :name, presence: true
  validates :login, presence: true
  validates :team_id, presence: true
  validates :role_id, presence: true
  validates :daily_rate,
            numericality: { greather_than: 0 },
            presence: true

  belongs_to :team
  belongs_to :role

  has_many :transactions
  has_many :tasks

  before_save :normalize_data

  scoped_search on: [:name, :login]
  scoped_search in: :team, on: :name, rename: :team, only_explicit: true
  scoped_search in: :role, on: :name, rename: :role, only_explicit: true

  def add_payment(comment, total)
    income_account.transactions.create total: total.abs,
                                        comment: comment,
                                        user_id: id
  end

  def paid_bonus(income, percentage)
    unless role.name == 'Manager'
      errors[:base] = "User should be a manager"
      return false
    end
    status = false
    self.transaction do
      total = (income / 100) * percentage
      co_team = Team.find_by_name!('Central Office')
      income_account.transactions.create! total: total,
                                          comment: "Bonus Calculation #{percentage}%",
                                          user_id: id
      team.income_account.transactions.create! total: -income,
                                               comment: "Income transfer #{team.name}",
                                               user_id: id
      co_team.income_account.transactions.create! total: -total,
                                                  comment: "Bonus Calculation #{percentage}% #{name}",
                                                  user_id: id
      co_team.income_account.transactions.create! total: income,
                                                  comment: "Income transfer #{team.name}",
                                                  user_id: id
      status = true
    end
    status
  end

  private

  def normalize_data
    self.login = self.login.downcase
    self.name = self.name.titleize
  end
end
