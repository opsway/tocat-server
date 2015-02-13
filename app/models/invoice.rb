class Invoice < ActiveRecord::Base
  validates_presence_of :external_id
  has_many :orders

  before_destroy :check_if_invoice_used
  before_save :handle_paid_status, if: Proc.new { |o| o.paid_changed?}

  private

  def handle_paid_status
    orders.each { |o| o.update_attributes(paid: paid)}
  end

  def check_if_invoice_used
    if orders.present?
      errors[:base] << 'Invoice is linked to orders'
      return false
    end
  end
end
