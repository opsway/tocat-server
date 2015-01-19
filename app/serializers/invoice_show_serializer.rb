class InvoiceShowSerializer < ActiveModel::Serializer
  attributes :id, :external_id, :paid, :links

  private

  def links
    data = {}
    data[:href] = invoice_path(object)
    data[:rel] = 'self'
    data
  end
end
