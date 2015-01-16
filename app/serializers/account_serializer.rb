class AccountSerializer < ActiveModel::Serializer
  attributes :id, :balance

  def attributes
    data = super
    data[:type] = object.account_type
    parent = {}
    parent[:type] = object.accountable_type
    parent[:id] = object.accountable_id
    data[:parent] = parent
    transactions = []
    object.transactions.each do |transaction|
      transaction_data = {}
      transaction_data[:id] = transaction.id
      transaction_data[:total] = transaction.total
      transaction_data[:comment] = transaction.comment
      account_parent = transaction.account.accountable
      transaction_data[:user] = {
        "id" => account_parent.id,
        "name" => account_parent.name,
        "role" => account_parent.role.name
        }
        transactions << transaction_data
    end
    data[:transactions] = transactions
    data
  end
end
