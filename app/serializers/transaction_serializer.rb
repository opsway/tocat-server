class TransactionSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :comment, :links

  def links
    data = {}
    data[:href] = v1_transaction_path(object)
    data[:rel] = "self"
    data
  end
end
