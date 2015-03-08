class OrderShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :invoiced_budget,
             :allocatable_budget,
             :free_budget,
             :name,
             :description,
             :paid,
             :completed,
             :parent_order,
             :invoice,
             :links,
             :team

  has_many :tasks
  has_many :sub_orders


  private

  def free_budget
    object.free_budget.to_f
  end

  def invoiced_budget
    object.invoiced_budget.to_f
  end

  def allocatable_budget
    object.allocatable_budget.to_f
  end

  def parent_order
    data = {}
    if object.parent # FIXME
      data[:href] = order_path(object.parent)
      data[:id] = object.parent.id
    end
    data
  end

  def invoice
    data = {}
    if object.invoice.present?
      data[:href] = invoice_path(object.invoice)
      data[:id] = object.invoice.id
    end
    data
  end

  def team
    data = {}
    data[:name] = object.team.name
    data[:href] = team_path(object.team)
    data[:id] = object.team.id
    data
  end

  def links
    data = []
    link_to_self = {}
    link_to_self[:href] = order_path(object)
    link_to_self[:rel] = 'self'
    data << link_to_self
    link_to_invoice = {}
    link_to_invoice[:href] = order_set_invoice_path(object)
    link_to_invoice[:rel] = 'invoice'
    data << link_to_invoice
    link_to_suborder = {}
    link_to_suborder[:href] = order_suborders_path(object)
    link_to_suborder[:rel] = 'suborder'
    data << link_to_suborder
    data
  end
end
