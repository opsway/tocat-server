class TransferRequest < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :source, class_name: User
  belongs_to :target, class_name: User
  belongs_to :balance_transfer
  validates :description, :total, presence: true
  validates :source_id, :target_id, presence: true
  validates :description, :length => { maximum: 250 }
  before_destroy :check_state_paid
  after_save :send_notification, unless: Proc.new { |t| t.state == 'paid' }
  after_save :send_notification_paid, if: Proc.new { |t| t.state == 'paid' }
  
  before_validation :set_state_and_target, if: Proc.new {|t| t.new_record? }
  validate :target_check_for_paid, if: Proc.new {|tr| tr.state_changed? && tr.state == 'paid' }
  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of internal invoice should be greater than 0"
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
      errors[:base] << "You can change only your internal invoice"
    end 
  end
  def check_state
    if state == 'paid' && !state_changed?
      errors[:base] << "You can't change paid internal invoice"
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
      errors[:base] << "Internal invoice have paid state, you can't remove it"
      return false
    end
    if target_id != User.current_user.id
      errors[:base] << "You can remove only your internal invoice"
      return false
    end
  end
  
  def target_check_for_paid
    if self.source_id != User.current_user.id
      errors[:base] << "You can pay only your internal invoice"
    end 
  end
  
  def set_state_and_target
    self.state = 'new'
    self.target = User.current_user
  end
  
  def send_notification
    AWS.config :access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.awss_secret_access_key
    ses = AWS::SimpleEmailService.new(
                                      :access_key_id => Settings.aws_access_key_id,
                                      :secret_access_key => Settings.aws_secret_access_key)
    host = Settings.email_host
    
    subject = "New internal invoice from #{target.name}"
    body = "Hello,\n You have new internal invoice: http://#{host}/tocat/internal_invoices/#{id} \n From: #{target.name}\n Total: #{total}\n Description: #{description}\n Yours sincerely,\n TOCAT"
    ses.send_email subject: subject, from: 'TOCAT@opsway.com', to: source.email, body_text: body
  end
  def   send_notification_paid
    host = Settings.email_host
    AWS.config :access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.aws_secret_access_key
    ses = AWS::SimpleEmailService.new(
                                      :access_key_id => Settings.aws_access_key_id,
                                      :secret_access_key => Settings.aws_secret_access_key)
    subject = "Internal invoice to #{source.name} was paid"
    body = "Hello,\n Your internal invoice was paid: http://#{host}/tocat/internal_invoices/#{id} \n From: #{source.name}\n Total: #{total}\n Description: #{description}\n Yours sincerely,\n TOCAT"
    ses.send_email subject: subject, from: 'TOCAT@opsway.com', to: target.email, body_text: body
    
  end
end
