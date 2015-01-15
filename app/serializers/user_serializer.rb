class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :login, :team, :role, :links

  def team
    data = {}
    data[:name] = object.team.name
    data[:href] = v1_team_path(object.team)
    data
  end

  def role
    "object.role.name" # TODO fix aftre role implementation
  end

  def links
    data = {}
    data[:href] = v1_user_path(object)
    data[:rel] = 'self'
    data
  end
end
