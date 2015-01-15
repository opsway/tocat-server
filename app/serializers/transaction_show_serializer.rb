class TransactionShowSerializer < ActiveModel::Serializer
  attributes :id

  def attributes
    data = super
    data[:timestamp] = object.created_at.to_f
    account = {}
    account[:id] = object.account.id
    account[:type] = object.account.account_type
    data[:account] = account
    data[:total] = object.total
    data[:comment] = object.comment
    data[:user_id] = object.user_id
    data
  end
end
