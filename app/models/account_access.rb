class AccountAccess < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  validate :uniqueness_of_default_for_user, if: :default?
  def uniqueness_of_default_for_user
    if default && self.user.account_access.where(default: true).joins(:account).where("accounts.account_type = ?", account.account_type).any?
      errors[:base] << 'You can have only one default account for any account type'
      false
    end
  end
end
