class Transaction < ActiveRecord::Base
  validates :account_id, presence: true
  validates :comment, presence: true
  validates :total,
            numericality: true,
            presence: true

  # validations for transactions thats created from api
  validate :check_comment, on: :api
  validate :check_owner, on: :api
  validate :check_total, on: :api
  #

  belongs_to :user
  belongs_to :team
  belongs_to :account

  scoped_search on: [:comment]
  scoped_search in: :account, on: :account_type, rename: :account, only_explicit: true



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

  private

  def check_comment
    comments = ["Paid in cash/bank"]
    unless comments.include?(comment)
      errors[:base] << "Invalid comment"
    end
  end

  def check_owner
    unless account.account_type == 'payment' && account.accountable_type == 'User'
      errors[:base] << "Invalid owner"
    end
  end

  def check_total
    if comment == 'Paid in cash/bank'
      # if account.accountable.income_account.abs > total.abs
      #   errors[:base] << "Total can't be more than owner income balace"
      # end
      errors[:base] << "Total for income account can't be greather than 0" if total > 0
    end
  end


end
