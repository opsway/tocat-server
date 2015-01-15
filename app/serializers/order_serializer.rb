class OrderSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes  :id,
              :name,
              :invoiced_budget,
              :allocatable_budget,
              :free_budget,
              :links

  def links
    data = {}
    data[:url] = v1_order_path(object)
    data[:rel] = 'self'
    data
  end
end
