class Account < ActiveRecord::Base
  validates :account_type, presence: true
  #validates :accountable_type, presence: true #TODO - maybe remove it
  #validates :accountable_id, presence: true #TODO - maybe remove it

  validate :check_account_type
  validate :check_accounts_amount

  scoped_search on: [:name, :account_type]

  before_save :set_name, if: :new_record?
  before_save :normalize_account_type

  belongs_to :accountable, polymorphic: true
  has_many :account_accesses
  has_many :transactions

  scope :with_accountable, -> (id, type) { Account.where(accountable_id: id, accountable_type: type.upcase) }

  def balance
    transactions.sum(:total)
  end
  
  def balance_account?
    account_type == 'balance'
  end
  
  def payroll_account?
    account_type == 'payroll'
  end
  
  def self.commission_user
    Rails.cache.fetch(expires_in: 1.minute) do
      User.find_by_login Rails.application.secrets[:tocat_manager]
    end
  end

  private

  def normalize_account_type
    self.account_type = self.account_type.downcase if self.account_type.present?
  end

  def check_account_type
    return unless account_type
    allowed_types = %w(balance payroll money)
    unless allowed_types.include? account_type.downcase
      errors.add(:account_type, 'contains wrong argument')
    end
  end

  def check_accounts_amount
    return unless accountable_id && accountable_type.present?
    amount = Account.where(accountable_id: accountable_id,
                           accountable_type: accountable.class.name)
                    .length
    errors[:base] << '2 accounts for this parent already exists.' if (amount >= 3)
  end
  def set_name
    self.name ||= "#{accountable.try(:name)} #{account_type}"
  end
end
