class InvoiceSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  
  attributes :id, :links

  private

  def links
    data = {}
    data[:href] = invoice_path(object)
    data[:rel] = 'self'
    data
  end
end
