class Team < ActiveRecord::Base
  include Accounts
  include PublicActivity::Common
  validates :name, presence: true
  has_many :orders
  has_many :users
  has_many :roles, :through => :users, source: :role
  def manager
    users.joins(:role).where('roles.name = ?', 'Manager').where(active: true).first
  end
  def self.central_office
    Team.where(name: 'Central Office').first
  end
end
