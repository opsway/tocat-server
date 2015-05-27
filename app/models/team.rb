class Team < ActiveRecord::Base
  include Accounts
  validates :name, presence: true
  has_many :orders
  has_many :users
end
