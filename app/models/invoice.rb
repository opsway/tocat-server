class Invoice < ActiveRecord::Base
  validates_presence_of :external_id
  has_many :orders

  before_destroy :check_if_invoice_used
  before_save :handle_paid_status, if: Proc.new { |o| o.paid_changed?}

  private
  def handle_paid_status
    self.transaction do
      orders.each do |order|
        order.tasks.each {|task| task.handle_paid(paid)}
        raise ActiveRecord::Rollback unless order.handle_paid(paid)
        order.sub_orders.each do |sub_order|
          sub_order.tasks.each {|task| task.handle_paid(paid)}
          raise ActiveRecord::Rollback unless sub_order.handle_paid(paid)
        end
      end
    end
  end

  def check_if_invoice_used
    if orders.present?
      errors[:base] << 'Invoice is linked to orders'
      false
    end
  end
end
