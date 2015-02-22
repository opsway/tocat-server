class Transaction < ActiveRecord::Base
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :total,
            numericality: true,
            presence: true

  belongs_to :user
  belongs_to :account

  scope :with_account_id, -> (account_id) { Transaction.where(account_id: account_id) }
end
