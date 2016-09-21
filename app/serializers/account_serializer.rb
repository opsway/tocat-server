class AccountSerializer < ActiveModel::Serializer
  attributes :id, :name, :balance, :access

  private

  def attributes
    data = super
    data[:type] = object.account_type
    data[:account_type] = object.account_type
    parent = {}
    parent[:type] = object.accountable_type
    parent[:id] = object.accountable_id
    parent[:name]= object.accountable.try :name
    data[:parent] = parent
    data
  end
  
  def access
    data = []
    object.account_accesses.each do |a|
      data << {id: a.user_id, name: a.user.name, default: a.default}
    end
    data
  end
end
