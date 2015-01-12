class Transaction < ActiveRecord::Base
  validates_presence_of :account_id
  validates_presence_of :user_id
  validates :total,
            :numericality => { :greater_than => 0 },
            :presence => true

  belongs_to :user
  belongs_to :account

end
