class Transaction < ActiveRecord::Base
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :total,
            numericality: true,
            presence: true

  belongs_to :user
  belongs_to :team
  belongs_to :account

  scoped_search :on => [:comment]



  scope :user, lambda { |id|
    ids = []
    Account.with_accountable(id, 'user').each do |account|
      ids << account.id
    end
    with_account_ids(ids)
  }

  scope :team, lambda { |id|
    ids = []
    Account.with_accountable(id, 'team').each do |account|
      ids << account.id
    end
    with_account_ids(ids)
  }

  scope :with_account_ids, -> (account_ids) { Transaction.where(account_id: [*account_ids]) }


end
