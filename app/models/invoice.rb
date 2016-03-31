require 'will_paginate/array'
class Invoice < ActiveRecord::Base
  include PublicActivity::Common
  validates :external_id,
            presence: { message: 'Missing external invoice ID' },
            uniqueness: { message: 'ID is already used' }

  has_many :orders

  before_destroy :check_if_invoice_used
  before_save :handle_paid_status, if: proc { |o| o.paid_changed? }

  scoped_search on: [:external_id, :paid]

  def total
    orders.sum(:invoiced_budget)
  end

  private

  def handle_paid_status
    self.transaction do
      handle_paid_for = lambda do |subject|
        subject.handle_paid(paid)
        subject.create_activity(
          :paid_update,
          parameters: {
            invoice_id: id,
            invoice_external_id: external_id,
            old: !paid,
            new: paid
          },
          owner: User.current_user)
      end
      orders.each do |order|
        handle_paid_for.call(order)
        order.sub_orders.each { |sub_order| handle_paid_for.call(sub_order) }
      end
      orders.each do |order|
        order.tasks.each { |task| handle_paid_for.call(task) }
        order.sub_orders.each do |sub_order|
          sub_order.tasks.each { |task| handle_paid_for.call(task) }
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
