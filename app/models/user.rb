class User < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :login
  validates_presence_of :balance_account
  validates_presence_of :income_account
  validates_presence_of :team_id
  validate :daily_rate,
           :numerical => {:greather_than => 0},
           :presence => true

  belongs_to :team
  #belongs_to :role
  has_many :transactions

  before_save :normalize_data


  private

    def normalize_data
      self.login = self.login.downcase
      self.name = self.name.titleize
    end
  end
