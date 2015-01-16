class TransactionSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :comment, :links

  private

  def links
    data = {}
    data[:href] = transaction_path(object)
    data[:rel] = 'self'
    data
  end
end
