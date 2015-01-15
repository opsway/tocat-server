class TeamSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :links

  def links
    data = {}
    data[:id] = object.id
    data[:href] = v1_team_path(object)
    data[:rel] = 'self'
    data
  end

end
