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

  private

  def parent_order
    data = {}
    if object.parent
      data[:href] = order_path(object.parent)
      data[:id] = object.parent.id
    end
    data
  end

  def invoice
    data = {}
    object.invoices.each do |invoice|
      data["#{invoice.id}"] = { 'href' => "#{order_path(object.parent)}/invoice" } # TODO refactor
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
    data = {}
    data[:id] = object.id
    data[:href] = order_path(object)
    data[:rel] = 'self'
    data
  end
end
