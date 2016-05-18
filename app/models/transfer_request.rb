class TransferRequest < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :source, class_name: User
  belongs_to :target, class_name: User
  has_one :balance_transfer
  validates :description, :total, presence: true
  validates :source_id, :target_id, presence: true
  validates :description, :length => { maximum: 250 }
  before_destroy :check_state_paid
  
  before_validation :set_state_and_source, if: Proc.new {|t| t.new_record? }
  validate :target_check_for_paid, if: Proc.new {|tr| tr.state_changed? && tr.state == 'paid' }
  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of balance transfer request should be greater than 0"
  validate :check_state
  validates :state, inclusion: {in: %w(new paid) }
  before_save :create_balance_transfer, if: Proc.new {|tr| tr.state_changed? && tr.state == 'paid' }

  private
  def check_state
    if state_changed? && state == 'new'
      errors[:base] << "You can't change transfer request"
      false
    end
  end

  def create_balance_transfer
    a = {
         total: total,
         description: description,
         source_id: target.income_account_id,
         target_id: source.income_account_id,
         state: 'base' 
        }
    bt = BalanceTransfer.create a
    self.balance_transfer = bt
  end
  
  def check_state_paid
    if state != 'new'
      errors[:base] << "Transfer request have paid state, you can't remove it"
      return false
    end
  end
  
  def target_check_for_paid
    if self.source != User.current_user
      errors[:base] << "You can pay only your transfer requests"
    end 
  end
  
  def set_state_and_source
    self.state = 'new'
    self.source = User.current_user
  end
end
