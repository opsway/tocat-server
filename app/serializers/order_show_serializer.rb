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
             :internal_order,
             :parent_order,
             :parent_id,
             :invoice,
             :links,
             :team,
             :commission

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
    if object.parent_id.present?
      data[:href] = order_path(object.parent_id)
      data[:id] = object.parent_id
    end
    data
  end

  def invoice
    data = {}
    if object.invoice_id.present?
      data[:href] = invoice_path(object.invoice_id)
      data[:id] = object.invoice_id
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
    data
  end
end
