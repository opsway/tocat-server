class PaymentRequestSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :source, :target, :source_account, :special, :description, :total, :currency, :created_at, :updated_at, :links, :history, :status
  
  def links
    data = {}
    data[:url] = payment_request_path(object)
    data[:rel] = 'self'
  end
  
  def source
    if object.source
      data = {}
      data[:name]= object.source.name
      data[:id]= object.source.id
      data
    end
  end
  
  def history
    if object.activities
      data = []
      object.activities.order('created_at asc').each do |activity|
        data << {name: activity.owner.try(:name), msg: activity.parameters[:status], date: activity.created_at}
      end
      data
    end
  end
  
  def target
    if object.target
      data = {}
      data[:name]= object.target.name
      data[:id]= object.target.id
      data
    end
  end
  
  def source_account
    data = {}
    data[:name] = object.source_account.try(:name)  || object.source.try(:name)
    data[:id] = object.source_account.try :id
    data
  end
end
