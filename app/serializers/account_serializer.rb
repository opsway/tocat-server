class AccountSerializer < ActiveModel::Serializer
  attributes :id

  def attributes
    data = {}
    data[:id] = object.id
    data[:type] = object.account_type
    data[:balance] = object.balance
    parent = {}
    parent[:type] = object.accountable_type
    parent[:id] = object.accountable_id
    data[:parent] = parent
    data
  end
end
