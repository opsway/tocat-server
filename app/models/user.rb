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


  private

  def normalize_data
    self.login = self.login.downcase
    self.name = self.name.titleize
  end
end
