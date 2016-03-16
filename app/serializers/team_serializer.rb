class TeamSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :links, :default_commission

  private

  def links
    data = {}
    data[:id] = object.id
    data[:href] = team_path(object)
    data[:rel] = 'self'
    data
  end
end
