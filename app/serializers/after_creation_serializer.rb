class AfterCreationSerializer < ActiveModel::Serializer
  attributes :id, :links, :review_requested

  private

  def review_requested
  	{review_requested: object.review_requested} unless object.try(:review_requested).nil?
  end

  def links
    data = {}
    data[:url] = "/#{object.class.name.downcase}/#{object.id}"
    data[:rel] = 'self'
    data
  end
end
