class Team < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :balance_account_id
  validates_presence_of :gross_profit_account
  has_many :orders
  has_many :accounts, as: :accountable
  has_many :users
end
