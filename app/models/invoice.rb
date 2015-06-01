require 'will_paginate/array'
class Invoice < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external invoice ID" }, uniqueness: { message: "ID is already used" }

  has_many :orders

  before_destroy :check_if_invoice_used
  before_save :handle_paid_status, if: proc { |o| o.paid_changed? }

  scoped_search on: [:external_id, :paid]

  def total
    orders.sum(:invoiced_budget)
  end

  def self.sorted_by_total(order)
    if order == 'asc'
      Invoice.all.sort_by(&:total)
    else
      Invoice.all.sort_by(&:total).reverse!
    end
  end

  private

  def handle_paid_status
    self.transaction do
      orders.each do |order|
        order.handle_paid(paid)
        order.sub_orders.each do |sub_order|
          sub_order.handle_paid(paid)
        end
      end
      orders.each do |order|
        order.tasks.each { |task| task.handle_paid(paid) }
        order.sub_orders.each do |sub_order|
          sub_order.tasks.each { |task| task.handle_paid(paid) }
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
