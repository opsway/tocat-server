class BalanceTransfer < ActiveRecord::Base # internal payment
  include PublicActivity::Common
  belongs_to :source, class_name: Account
  belongs_to :target, class_name: Account
  belongs_to :target_transaction, class_name: Transaction
  belongs_to :source_transaction, class_name: Transaction
  validates :description, :total, :source_id, :target_id, :presence => true
 
  validates :description, length: { maximum: 250 }
  attr_accessor :target_login
  validate :account_balance_with_transaction_commission

  validates_numericality_of :total, 
                            greater_than: 0,
                            message: "Total of internal payment should be greater than 0"
  before_validation :set_date
  before_save :create_transactions
  after_save :send_notification_payment
  #scoped_search in: :source, on: :accountable_id, rename: :source
  #scoped_search in: :target, on: :accountable_id, rename: :target
  
  def as_json(options={})
    additional_params = {source: source.try(:accountable).try(:name)||source.try(:name), target: target.try(:accountable).try(:name)||target.try(:name)}
    self.attributes.merge additional_params
  end

  private
  
  def account_balance_with_transaction_commission
    if total > source.balance && !User.current_user.coach
      errors[:base] << 'You can not pay more that you have (including Transaction Commission)'
    end
    if !User.current_user.coach && target.pay_comission && total >= Setting.transactional_micropayment && target.balance + total < Setting.transactional_commission
      errors[:base] << "Target account can't receive money"
    end
  end
  
  def set_date
    self.created = Time.now
  end
  
  def create_transactions
    comment = "Balance transfer:  #{self.description}".truncate 255 # TODO - transaction comment should be not more 255 symbols
    self.source_transaction = source.transactions.create! total: -total, comment: comment
    self.target_transaction = target.transactions.create! total: total, comment: comment
  end

  def send_notification_payment
    host = Settings.email_host
    AWS.config :access_key_id => Settings.aws_access_key_id, :secret_access_key => Settings.aws_secret_access_key
    ses = AWS::SimpleEmailService.new(
                                      :access_key_id => Settings.aws_access_key_id,
                                      :secret_access_key => Settings.aws_secret_access_key)
    subject = "Internal payment from #{source.name}"
    body = "Hello,\n You have internal payment payment: http://#{host}/tocat/internal_payments/#{id} \n From: #{source.name}\n Total: #{total}\n Description: #{description}\n Yours sincerely,\n TOCAT"
    if Rails.env.production?
      ses.send_email subject: subject, from: 'TOCAT@opsway.com', to: target.email, body_text: body
    end
  end
end
