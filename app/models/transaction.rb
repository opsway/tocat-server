class Transaction < ActiveRecord::Base
  validates :account_id, presence: true
  validates :comment, presence: true
  validates :total,
            numericality: true,
            presence: true

  belongs_to :user
  belongs_to :team
  belongs_to :account

  scoped_search on: [:comment, :created_at]
  scoped_search in: :account, on: :account_type, rename: :account, only_explicit: true
  scoped_search in: :account, on: :accountable_id, only_explicit: true
  scoped_search in: :account, on: :accountable_type, only_explicit: true
  scoped_search in: :user, on: :name, rename: :user, only_explicit: true
  
  after_save :take_coach_transaction_commission





  scope :user, lambda { |id|
    ids = Account.with_accountable(id, 'user').pluck(:id)
    with_account_ids(ids) # TODO refactor
  }

  scope :team, lambda { |id|
    ids = Account.with_accountable(id, 'team').pluck(:id)
    with_account_ids(ids) # TODO refactor
  }

  scope :with_account_ids, -> (account_ids) { Transaction.where(account_id: [*account_ids]) }

  # def destroy
  #   fail "Transaction cannot be destroyed"
  # end

  # alias_method :destroy!, :destroy
  # alias_method :delete, :destroy
  # alias_method :delete!, :destroy

  # def self.destroy_all
  #   fail "Transactions cannot be destroyed"
  # end

  # def self.destroy_all!
  #   fail "Transactions cannot be destroyed"
  # end

  # def self.delete_all
  #   fail "Transactions cannot be destroyed"
  # end

  # def self.delete_all!
  #   fail "Transactions cannot be destroyed"
  # end
  
  private
  def take_coach_transaction_commission
    if account.accountable.try(:real_money?) && total >= 10 && account.accountable.try(:login) != Account.commission_user.login 
      
      Transaction.where(comment: "Transactional Commission for transaction id=#{id}", total: -10, account: account, user_id: account.accountable_id, created_at: created_at).first_or_create
      Transaction.where(comment: "Transactional Commission for transaction id=#{id}", total:  10, account: Account.commission_user.income_account, user_id: account.accountable_id, created_at: created_at).first_or_create
    end
  end
end
