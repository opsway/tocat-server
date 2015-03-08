class TransactionSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,:total,:type, :comment, :links

  private

  def type
    object.account.account_type
  end

  def links
    data = {}
    data[:href] = transaction_path(object)
    data[:rel] = 'self'
    data
  end
end
