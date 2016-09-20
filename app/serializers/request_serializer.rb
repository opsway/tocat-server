class RequestSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :total, :description, :source, :target, :state, :created_at, :links
  #belongs_to :source
  #belongs_to :target
  private
  def source
    if object.source_account
      data = {}
      data[:id] = object.source_account.id
      data[:name] = object.source_account.name
      data
    end
  end
  def target
    if object.target_account
      data = {}
      data[:id] = object.target_account.id
      data[:name] = object.target_account.name
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
