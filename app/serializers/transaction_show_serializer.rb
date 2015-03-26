class TransactionShowSerializer < ActiveModel::Serializer
  attributes :id, :total, :comment, :owner

  private

  def owner
    {
      id: object.account.accountable_id,
      type: object.account.accountable.class.name.downcase,
      href: "/#{object.account.accountable.class.name.downcase}/#{object.account.accountable_id}"
    }
  end

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
