class TransactionSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :total, :owner, :type, :comment, :links, :date

  private

  def owner
    {
      id: object.account.accountable_id,
      type: object.account.accountable.class.name.downcase,
      name: object.account.name.to_s,
      href: "/#{object.account.accountable.class.name.downcase}/#{object.account.accountable_id}"
    }
  end

  def date
    object.created_at
  end

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
