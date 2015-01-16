class Account < ActiveRecord::Base
  validates_presence_of :account_type
  validates_presence_of :accountable_type
  validates_presence_of :accountable_id

  validate :check_account_type
  validate :check_accounts_amount

  before_save :normalize_account_type

  belongs_to :accountable, polymorphic: true
  has_many :transactions

  def balance
    value = BigDecimal.new 0
    binding.pry
    transactions.each { |t| value += t.total }
    value
  end

  private

  def normalize_account_type
    account_type = account_type.downcase if account_type.present?
  end

  def check_account_type
    return unless(account_type)
    allowed_types = %w(balance payment)
    unless allowed_types.include? account_type.downcase
      errors.add(:account_type, 'contains wrong argument')
    end
  end

  def check_accounts_amount
    return unless(accountable_id and accountable_type)
    amount = Account.where(accountable_id: accountable_id,
                            accountable_type: accountable.class.name)
                              .length
    if(amount >= 2)
      errors[:base] << '2 accounts for this parent already exists.'
    end
  end
end
