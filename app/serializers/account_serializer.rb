class AccountSerializer < ActiveModel::Serializer
  attributes :id, :balance

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
end
