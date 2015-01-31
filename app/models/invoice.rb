class Invoice < ActiveRecord::Base
  validates_presence_of :external_id
  belongs_to :order

  before_destroy :check_if_invoice_used

  private

  def check_if_invoice_used
    if order.present?
      errors[:base] << 'Invoice is linked to orders'
      return false
    end
  end
end
