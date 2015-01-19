class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :links

  private

  def links
    data = {}
    data[:href] = invoice_path(object)
    data[:rel] = 'self'
    data
  end
end
