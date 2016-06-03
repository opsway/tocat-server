class PaymentRequest < ActiveRecord::Base
  include AASM
  include PublicActivity::Common
  
  #scoped search
  scoped_search on: :status
  
  #association
  has_and_belongs_to_many :users
  belongs_to :source, class_name: User
  belongs_to :target, class_name: User
  belongs_to :salary_account, class_name: Account

  #callbacks
  before_validation :set_source_user
  after_save :add_current_user
  after_save :notify_all, if: Proc.new{|t| t.status == 'new' || t.status_changed?}
  
  #validations
  validates :source, :total, :description, presence: true
  validates :description, :length => { maximum: 250 }

  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of payment request should be greater than 0"
  validates :currency, inclusion: {in: %w(USD EUR UAH RUR KZT)}
  
  validates :target, presence: true, if: Proc.new {|t| t.special? }
  validates :currency, inclusion: {in: %w(USD )}, if: Proc.new{|t| t.special? }
  validates :salary_account, presence: true, if: Proc.new{|t| t.special?}

  
  aasm :column => 'status' do
    state :new, initial: true
    state :approved, :dispatched, :canceled, :rejected, :completed
    
    event :approve do
      transitions :from => :new, :to => :approved, :guard => :approve_allowed?
    end
    event :cancel do
      transitions :from => :new, :to => :canceled, :guard => :cancel_allowed?
    end
    
    event :complete, after: :process_special do
      transitions :from => :dispatched, :to => :completed, :guard => :complete_allowed?
    end
    event :reject do
      transitions :from => [:dispatched, :approved], :to => :rejected, :guard => :reject_allowed?
    end
    
    event :dispatch do
      transitions :from => :approved, :to => :dispatched, :guard => :dispatch_allowed?
    end
  end
  def edit_allowed?
    return false unless new?
    return true if source_id == User.current_user.try(:id)
    return false unless User.current_user.try(:role).try(:manager?)
    User.current_user.try(:team).try(:all_children).try(:include?, self.source.team.id)
  end
  private 
  def dispatch_allowed?
    true
  end
  def reject_allowed?
    true
  end
  
  def cancel_allowed?
    return true if source_id == User.current_user.try(:id)
    as_manager
  end
  
  def approve_allowed?
    as_manager?
  end

  def as_manager?
    return false unless User.current_user.try(:role).try(:manager?)
    User.current_user.try(:team).try(:all_children).try(:include?, self.source.team.id)
  end
  
  def complete_allowed?
    true
  end
  
  def process_special
    if special?
      Transaction.create!(comment: "Paid in cash/bank",
                          total: "-#{self.total}",
                          account: salary_account,
                          user_id: salary_account.accountable.id)
    end
  end

  def notify_all
    self.create_activity :status_change, parameters: {status: "Status changed to #{status}"}, owner: User.current_user

    subj = case status
    when 'new'
      "Payment Request Created"
    else
      "Payment Request #{status.capitalize}"
    end
    
    AWS.config :access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.aws_secret_access_key
    ses = AWS::SimpleEmailService.new(
                                      :access_key_id => Settings.aws_access_key_id,
                                      :secret_access_key => Settings.aws_secret_access_key)
    host = Settings.email_host
    body = "Hello,\n Payment request: http://#{host}/tocat/payment_requests/#{id} \n From: #{source.name}\n Status: #{status}\n Total: #{total}#{currency}\n Description: #{description}\n Yours sincerely,\n TOCAT"

    self.users.where.not(id: User.current_user.id).each do |user|
      begin
      ses.send_email subject: subj, from: 'TOCAT@opsway.com', to: user.email, body_text: body
      rescue
      end
    end
  end
  def set_source_user
    self.source ||= User.current_user
  end
  def add_current_user
    self.users << User.current_user unless self.user_ids.include?(User.current_user.id)
  end
end
