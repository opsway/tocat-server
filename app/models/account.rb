class Account < ActiveRecord::Base
  validates_presence_of :account_type
  validate :check_account_type
  before_save :normalize_account_type
  #belongs_to :team
  #belongs_to :user
  belongs_to :accountable, polymorphic: true
  has_many :transactions

  private

  def normalize_account_type
    self.account_type = self.account_type.downcase
  end

  def check_account_type
    allowed_types = %w(balance payment)
    unless allowed_types.include? account_type.downcase
      errors.add(:account_type, "contains wrong argument")
    end
  end
end
