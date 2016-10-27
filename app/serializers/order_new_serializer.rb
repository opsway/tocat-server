class OrderNewSerializer < ActiveModel::Serializer
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
             :reseller,
             :team,
             :invoice,
             :commission

  private

  def suborder
    object.parent_id.present?
  end
end
