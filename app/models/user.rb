class User < ActiveRecord::Base
  include PublicActivity::Common
  has_many :account_access
  has_many :accounts, through: :account_access
  validates :name, presence: true
  validates :login, presence: true
  validates :daily_rate,
            numericality: { greather_than: 0 },
            presence: true

  validates :email, presence: true, uniqueness: true, format: /@/
  belongs_to :team
  belongs_to :role
  validates :team_id, presence: true
  validates :role_id, presence: true
  validate :team_can_have_only_one_manager
  validate :team_can_have_only_one_member_coach

  has_many :transactions
  has_many :tasks
  has_one :tocat_user_role, class_name: "TocatUserRole"
  has_one :tocat_role, through: :tocat_user_role, class_name: "TocatRole"

  
  has_and_belongs_to_many :payment_requests

  before_save :normalize_data
  scope :all_active, ->{where(active: true)}

  scoped_search on: [:name, :login, :email, :coach, :active]
  scoped_search in: :team, on: :name, rename: :team, only_explicit: true
  scoped_search in: :role, on: :name, rename: :role, only_explicit: true

  enum billable: {billable: 1, non_billable: 0}
  
  def tocat_allowed_to?(action)
    self.tocat_role.try(:permissions).try(:include?, action)
  end

  delegate :manager?, to: :role

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(usr)
    Thread.current[:current_user] = usr
  end

  def add_payment(comment, total)
    self.transaction do
      payroll_account.transactions.create! total: -total.to_i,
                                          comment: comment,
                                          user_id: id
      create_activity key: 'user.add_payment',
                      parameters: { total: -total.to_i, comment: comment },
                      recipient: self,
                      owner: User.current_user
    end
  end
  def available_accounts
    @accounts =  [money_account]
    @accounts += Account.joins(:account_accesses).where('account_accesses.default = false and user_id = ?', id).to_a
    @accounts
  end

  def default_account(account_type)
    Account.where(account_type: account_type).joins(:account_accesses).where('account_accesses.default = true and user_id = ?', id).first
  end

  def payroll_account
    default_account 'payroll'
  end

  def money_account
    default_account 'money'
  end
  
  def balance_account
    default_account 'balance'
  end
  
  after_create :create_accounts

  private

  def create_accounts
    self.accounts.create! account_type: 'balance', name: name, accountable_id: id, accountable_type: 'User'
    self.accounts.create! account_type: 'payroll', name: name, accountable_id: id, accountable_type: 'User'
    self.accounts.create! account_type: 'money', name: name, accountable_id: id, accountable_type: 'User'
    account_access.update_all(default: true)
    self.accounts.map(&:save)
  end

  def normalize_data
    self.login = self.login.downcase
    self.name = self.name.titleize
  end
  def team_can_have_only_one_manager
    errors.add 'Team', 'already have a manager' if self.role.try(:name) == 'Manager' && self.team.users.where.not(id: self.id).where(active: true, role_id: Role.managers.select(:id)).any? #TODO - fix 
  end
  def team_can_have_only_one_member_coach
    if self.coach
      errors.add 'Team', 'already have a user with real money' if self.team.users.where.not(id: self.id).where(active: true, coach: true).any?
    end
  end
end
