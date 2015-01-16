class AccountSerializer < ActiveModel::Serializer
  attributes :id, :balance, :transactions

  private

  def attributes
    data = super
    data[:type] = object.account_type
    parent = {}
    parent[:type] = object.accountable_type
    parent[:id] = object.accountable_id
    data[:parent] = parent
    data
  end

  def transactions
    transactions = []
    object.transactions.each do |transaction|
      transaction_data = {}
      transaction_data[:id] = transaction.id
      transaction_data[:total] = transaction.total
      transaction_data[:comment] = transaction.comment
      account_parent = transaction.account.accountable
      owner = {}
      owner[:id] = account_parent.id
      owner[:name] = account_parent.name
      transaction_data[:owner] = owner
      transactions << transaction_data
    end
    transactions
  end
end
