class PaymentRequest < ActiveRecord::Base # external payment
  include AASM
  include PublicActivity::Common
  
  #scoped search
  scoped_search on: :status
  
  #association
  has_and_belongs_to_many :users
  belongs_to :source, class_name: User
  belongs_to :target, class_name: User
  belongs_to :salary_account, class_name: Account
  belongs_to :source_account, class_name: Account

  #callbacks
  before_validation :set_source_user
  after_save :add_current_user
  after_save :notify_all, if: Proc.new{|t| t.status == 'new' || t.status_changed?}
  
  #validations
  validates :source, :total, :description, presence: true
  validates :description, :length => { maximum: 250 }

  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of external payment should be greater than 0"
  validates :currency, inclusion: {in: %w(USD EUR UAH RUR KZT)}
  validates :target, presence: true, if: Proc.new {|t| t.status == 'dispatched' }
  validates :currency, inclusion: {in: %w(USD )}, if: Proc.new{|t| t.special? }
  after_create :make_transactions
  validate :check_balance
  after_initialize :set_currency

  
  aasm :column => 'status' do
    state :new, initial: true
    state :canceled, :completed
    
    event :cancel, after: :make_back_transactions do
      transitions :from => :new, :to => :canceled, :guard => :cancel_allowed?
    end
    
    event :complete do
      transitions :from => :new, :to => :completed, :guard => :complete_allowed?
    end
  end

  def edit_allowed?
    return false unless new?
    return true if source_id == User.current_user.try(:id)
    return false unless User.current_user.try(:role).try(:manager?)
    User.current_user.try(:team).try(:all_children).try(:include?, self.source.team.id)
  end

  private 
  def make_transactions
    commission = total*Setting.external_payment_commission/100.0
    commission = 5.0 if commission < 5
    source_account.transactions.create(total: - (total + commission), comment: "External payment #{id}", not_take_transactions: true)
    Account.find(Setting.finance_fund_account_id).transactions.create(total: total + commission, comment: "External payment #{id}", not_take_transactions: true)
  end
  def make_back_transactions
    commission = total*Setting.external_payment_commission/100.0
    commission = 5.0 if commission < 5
    source_account.transactions.create(total: + (total + commission), comment: "Cancel external payment #{id}", not_take_transactions: true)
    Account.find(Setting.finance_fund_account_id).transactions.create(total: - (total + commission), comment: "Cancel external payment #{id}", not_take_transactions: true)
  end
  
  def check_balance
    commission = [5.0, total.to_f*Setting.finance_commission/100.0].max
    if source_account.balance <= (total.to_f + commission) and !source.coach
      errors[:base] << "You can not pay more than you have (including External Payment Comission)"
      false
    end
  end
  
  def dispatch_allowed?
    true
  end
  def reject_allowed?
    true
  end
  
  def cancel_allowed?
    return false unless User.current_user.account_access.where(account_id: source_account.id).any?
    return true if source_id == User.current_user.try(:id)
    as_manager?
  end
  
  def as_manager?
    return false unless User.current_user.try(:role).try(:manager?)
    User.current_user.try(:team).try(:all_children).try(:include?, self.source.team.id)
  end
  
  def complete_allowed?
    return false unless User.current_user.account_access.where(account_id: source_account.id).any?
    true
  end
  
  def notify_all
    self.create_activity :status_change, parameters: {status: "Status changed to #{status}"}, owner: User.current_user

    subj = case status
    when 'new'
      "External Payment Created"
    else
      "External Payment #{status.capitalize}"
    end
    
    AWS.config :access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.aws_secret_access_key
    ses = AWS::SimpleEmailService.new(
                                      :access_key_id => Settings.aws_access_key_id,
                                      :secret_access_key => Settings.aws_secret_access_key)
    host = Settings.email_host
    body = "Hello,\n External Payment: http://#{host}/tocat/external_payments/#{id} \n From: #{source.name}\n Status: #{status}\n Total: #{total}#{currency}\n Description: #{description}\n Yours sincerely,\n TOCAT"

    self.users.where.not(id: User.current_user.id).each do |user|
      begin
      ses.send_email subject: subj, from: 'TOCAT@opsway.com', to: user.email, body_text: body
      rescue
      end
    end
    if Rails.env.production?
      ses.send_email subject: subj, from: 'TOCAT@opsway.com', to: Setting.finance_service_email, body_text: body
    end
  end
  def set_source_user
    self.source ||= User.current_user
  end
  def add_current_user
    self.users << User.current_user unless self.user_ids.include?(User.current_user.id)
  end
  
  def set_currency
    self.currency ||= 'USD'
  end
end
