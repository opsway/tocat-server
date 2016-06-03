class PaymentRequestSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :source, :target, :salary_account, :special, :description, :total, :currency, :created_at, :updated_at, :links, :history, :status
  
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
  
  def salary_account
    if object.special && object.salary_account
      data = {}
      data[:name] = object.salary_account.accountable.name
      data[:user_id] = object.salary_account.accountable.id
      data[:id] = object.salary_account.id
    end
  end
end
