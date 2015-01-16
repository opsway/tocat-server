class TransactionShowSerializer < ActiveModel::Serializer
  attributes :id, :total, :comment, :user_id

  private

  def attributes
    data = super
    data[:timestamp] = object.created_at.to_f
    account = {}
    account[:id] = object.account.id
    account[:type] = object.account.account_type
    data[:account] = account
    data
  end
end
