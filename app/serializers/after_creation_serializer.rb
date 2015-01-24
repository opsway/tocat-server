class AfterCreationSerializer < ActiveModel::Serializer
  attributes :id, :links

  private

  def links
    data = {}
    data[:url] = "/#{object.class.name.downcase}/#{object.id}"
    data[:rel] = 'self'
    data
  end
end
