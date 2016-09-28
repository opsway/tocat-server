class RequestSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :total, :description, :source, :target, :state, :created_at, :links
  #belongs_to :source
  #belongs_to :target
  private
  def source
    if object.source_account || object.source
      data = {}
      data[:id] = object.source_account.try :id
      data[:name] = object.source_account.try(:name) || object.source.try(:name)
      data
    end
  end
  def target
    if object.target_account || object.target
      data = {}
      data[:id] = object.target_account.try :id
      data[:name] = object.target_account.try(:name) || object.target.try(:name)
      data
    end
  end
  
  def links
    data = {}
    data[:url] = transfer_request_path(object)
    data[:rel] = 'self'
    data
  end
end
