class BalanceTransfer < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :source, class_name: Account
  belongs_to :target, class_name: Account
  belongs_to :target_transaction, class_name: Transaction
  belongs_to :source_transaction, class_name: Transaction
  validates :source, :target, :description, :total ,:presence => true
  validates :description, length: { maximum: 250 }
  attr_accessor :target_login

  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of balance transfer should be greater than 0"
  before_validation :set_source_account
  before_validation :set_target_account
  before_validation :set_date
  after_validation :create_transactions
  #scoped_search in: :source, on: :accountable_id, rename: :source
  #scoped_search in: :target, on: :accountable_id, rename: :target
  
  def as_json(options={})
    additional_params = {source: source.accountable.name, target: target.accountable.name}
    self.attributes.merge additional_params
  end

  private
  
  def set_date
    self.created = Time.now
  end
  
  def set_source_account
    self.source = User.current_user.try(:balance_account)
  end
  def set_target_account
    self.target = User.find_by_login(target_login).try(:balance_account)
  end
  

  def create_transactions
    comment = "Balance transfer:  #{self.description}"
    self.source_transaction = source.transactions.create! total: -total, comment: comment
    self.target_transaction = target.transactions.create! total: total, comment: comment
  end
end
