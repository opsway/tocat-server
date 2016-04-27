class BalanceTransfer < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :source, class_name: Account
  belongs_to :target, class_name: Account
  belongs_to :target_transaction, class_name: Transaction
  belongs_to :source_transaction, class_name: Transaction
  validates :description, :total ,:presence => true
 
  validates :source, presence: true, unless: Proc.new {|a| a.btype == 'emit'}
  validates :target, presence: true, unless: Proc.new {|a| a.btype == 'takeout'}
  validates :btype, inclusion: {in: %w(base emit takeout) }

  validates :description, length: { maximum: 250 }
  attr_accessor :target_login

  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of balance transfer should be greater than 0"
  before_validation :set_source_account, unless: Proc.new {|a| a.btype == 'emit'}
  before_validation :set_target_account, unless: Proc.new {|a| a.btype == 'takeout'}
  before_validation :set_date
  after_validation :create_transactions
  #scoped_search in: :source, on: :accountable_id, rename: :source
  #scoped_search in: :target, on: :accountable_id, rename: :target
  
  def as_json(options={})
    additional_params = {source: source.try(:accountable).try(:name), target: target.try(:accountable).try(:name)}
    self.attributes.merge additional_params
  end

  private
  
  def set_date
    self.created = Time.now
  end
  
  def set_source_account
    if self.btype == 'takeout'
      self.source = Team.central_office.manager.try(:balance_account)
    else
      self.source = User.current_user.try(:balance_account)
    end
  end

  def set_target_account
    if self.btype == 'emit'
      self.target = Team.central_office.manager.try(:balance_account)
    else
      self.target = User.find_by_login(target_login).try(:balance_account)
    end
  end
  
  def create_transactions
    comment = "Balance transfer:  #{self.description}"
    case self.btype
    when 'base'
      self.source_transaction = source.transactions.create! total: -total, comment: comment
      self.target_transaction = target.transactions.create! total: total, comment: comment
    when 'emit'
      self.target_transaction = target.transactions.create! total: total, comment: comment
    when 'takeout'
      self.source_transaction = source.transactions.create! total: -total, comment: comment
    end
  end
end
