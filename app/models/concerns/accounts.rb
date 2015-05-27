module Accounts
  extend ActiveSupport::Concern

  included do
    has_many :accounts, as: :accountable, dependent: :destroy
    after_create :create_accounts
    after_destroy :destroy_accounts
  end

  def balance_account
    Account.where(accountable_id: self.id,
                  accountable_type: self.class.name,
                  account_type: 'balance').first
  end

  def income_account
    Account.where(accountable_id: self.id,
                  accountable_type: self.class.name,
                  account_type: 'payment').first
  end

  private

  def create_accounts
    self.accounts.create! account_type: 'balance'
    self.accounts.create! account_type: 'payment'
  end

  def destroy_accounts
    self.accounts.destroy_all
  end
end
