class User < ActiveRecord::Base
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
  has_many :accounts, as: :accountable
  has_many :tasks

  before_save :normalize_data
  after_create :create_accounts
  after_destroy :destroy_accounts

  def balance_account
    Account.where(accountable_id: self.id,
                  accountable_type: self.class.name,
                  account_type: 'balance').first
  end

  def income_account
    Account.where(accountable_id: self.id,
                  accountable_type: self.class.name,
                  account_type: 'payment').first
  end

  private

  def create_accounts
    balance = self.accounts.create! account_type: 'balance'
    payment = self.accounts.create! account_type: 'payment'
    self.balance_account_id = balance.id
    self.income_account_id = payment.id
    self.save!
  end

  def destroy_accounts
    self.accounts.destroy_all
  end

  def normalize_data
    self.login = self.login.downcase
    self.name = self.name.titleize
  end
end
