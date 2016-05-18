class RequestSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :total, :description, :source, :target, :created, :links
  #belongs_to :source
  #belongs_to :target
  private
  def source
    if object.source
      data = {}
      data[:id] = object.source.id
      data[:name] = object.source.name
      data
    end
  end
  def target
    if object.target
      data = {}
      data[:id] = object.target.id
      data[:name] = object.target.name
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
