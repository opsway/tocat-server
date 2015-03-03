class InvoiceShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,:client, :total, :external_id, :paid, :links

  has_many :orders

  private

  def links
    data = {}
    data[:href] = invoice_path(object)
    data[:rel] = 'self'
    data
  end
end
