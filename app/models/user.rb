class User < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :login
  validates_presence_of :balance_account
  validates_presence_of :income_account
  validates_presence_of :team_id
  validates_presence_of :role_id

  validates :daily_rate,
            :numericality => {:greather_than => 0},
            :presence => true

  belongs_to :team
  belongs_to :role

  has_many :transactions
  has_many :accounts, as: :accountable

  before_save :normalize_data


  private

    def normalize_data
      self.login = self.login.downcase
      self.name = self.name.titleize
    end
  end
