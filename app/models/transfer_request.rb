class TransferRequest < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :source, class_name: User
  belongs_to :target, class_name: User
  belongs_to :balance_transfer
  validates :description, :total, presence: true
  validates :source_id, :target_id, presence: true
  validates :description, :length => { maximum: 250 }
  before_destroy :check_state_paid
  
  before_validation :set_state_and_target, if: Proc.new {|t| t.new_record? }
  validate :target_check_for_paid, if: Proc.new {|tr| tr.state_changed? && tr.state == 'paid' }
  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of balance transfer request should be greater than 0"
  validates :state, inclusion: {in: %w(new paid) }
  validate :check_state, if: Proc.new{|t| t.persisted? }
  validate :check_target, if: Proc.new{|t| t.persisted? }
  before_save :create_balance_transfer, if: Proc.new {|tr| tr.state_changed? && tr.state == 'paid' }
  
  def as_json(options = {})
    additional_params = { source: source.try(:name), target: target.try(:name) }
    self.attributes.merge additional_params
  end

  private
  def check_target
    if self.target_id != User.current_user.id && state != 'paid'
      errors[:base] << "You can change only your transfer requests"
    end 
  end
  def check_state
    if state == 'paid' && !state_changed?
      errors[:base] << "You can't change paid transfer request"
      false
    end
  end

  def create_balance_transfer
    a = {
         total: total,
         description: description,
         source_id: source.income_account.id,
         target_id: target.income_account.id,
         btype: 'base' 
        }
    bt = BalanceTransfer.create a
    self.balance_transfer = bt
    return bt.persisted?
  end
  
  def check_state_paid
    if state != 'new' 
      errors[:base] << "Transfer request have paid state, you can't remove it"
      return false
    end
    if target_id != User.current_user.id
      errors[:base] << "You can remove only your transfer request"
      return false
    end
  end
  
  def target_check_for_paid
    if self.source_id != User.current_user.id
      errors[:base] << "You can pay only your transfer requests"
    end 
  end
  
  def set_state_and_target
    self.state = 'new'
    self.target = User.current_user
  end
end
