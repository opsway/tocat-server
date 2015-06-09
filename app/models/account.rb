class Account < ActiveRecord::Base
  validates :account_type, presence: true
  validates :accountable_type, presence: true
  validates :accountable_id, presence: true

  validate :check_account_type
  validate :check_accounts_amount

  before_save :normalize_account_type

  belongs_to :accountable, polymorphic: true
  has_many :transactions

  scope :with_accountable, -> (id, type) { Account.where(accountable_id: id, accountable_type: type.upcase) }

  def balance
    transactions.sum(:total)
  end

  private

  def normalize_account_type
    self.account_type = self.account_type.downcase if self.account_type.present?
  end

  def check_account_type
    return unless account_type
    allowed_types = %w(balance payment)
    unless allowed_types.include? account_type.downcase
      errors.add(:account_type, 'contains wrong argument')
    end
  end

  def check_accounts_amount
    return unless accountable_id && accountable_type
    amount = Account.where(accountable_id: accountable_id,
                           accountable_type: accountable.class.name)
                    .length
    errors[:base] << '2 accounts for this parent already exists.' if (amount >= 2)
  end
end
