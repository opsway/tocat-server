class OrderSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :invoiced_budget,
             :allocatable_budget,
             :free_budget,
             :suborder,
             :paid,
             :completed,
             :internal_order,
             :zohobooks_project_id,
             :accrual_completed_date,
             :reseller,
             :team,
             :invoice,
             :links

  private

  def invoice
    data = {}
    if object.invoice.present?
      data[:id] = object.invoice.id
      data[:external_id] = object.invoice.external_id
      data[:link] = invoice_path(object.invoice)
    end
    data
  end

  def team
    data = {}
    data[:id] = object.team.id
    data[:name] = object.team.name
    data[:link] = team_path(object.team)
    data
  end

  def suborder
    object.parent_id.present?
  end

  def links
    data = {}
    data[:url] = order_path(object)
    data[:rel] = 'self'
    data # TODO add more links, as in apiary
  end
end
