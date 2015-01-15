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
    transactions = []
    object.transactions.each do |t|
      _t = {}
      _t[:id] = t.id
      _t[:total] = t.total
      _t[:comment] = t.comment
      _t[:user] = {
        "id" => t.user_id,
        "name" => t.user.name,
        "role" => "t.user.role.name" # TODO fix after role implementation
        }
        transactions << _t
    end
    data[:transactions] = transactions
    data
  end
end
