class BtShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :total, :description, :source, :target, :created, :links
  #belongs_to :source
  #belongs_to :target
  private
  def source
    data = {}
    data[:id] = object.source.accountable_id
    data[:name] = object.source.accountable.name
    data
  end
  def target
    data = {}
    data[:id] = object.target.accountable_id
    data[:name] = object.target.accountable.name
    data
  end
  
  def links
    data = {}
    data[:url] = balance_transfer_path(object)
    data[:rel] = 'self'
    data
  end
end
