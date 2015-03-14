class OrderSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :invoiced_budget,
             :allocatable_budget,
             :free_budget,
             :suborder,
             :paid,
             :team
             :links

  private
  
  def suborder
    object.parent_id.present?
  end

  def team
    {name: object.team.name, id: object.team.id}
  end

  def links
    data = {}
    data[:url] = order_path(object)
    data[:rel] = 'self'
    data # TODO add more links, as in apiary
  end
end
