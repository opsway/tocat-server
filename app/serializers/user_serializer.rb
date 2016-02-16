class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :login, :tocat_team, :tocat_server_role, :links, :balance_account_state, :income_account_state, :active, :daily_rate

  private

  def tocat_team
    data = {}
    team = object.team
    data[:id] = team.id
    data[:name] = team.name
    data[:href] = team_path(team)
    data
  end

  def tocat_server_role
    data = {}
    data[:id] = object.role.id
    data[:name]= object.role.name
    data
  end

  def links
    data = {}
    data[:href] = user_path(object)
    data[:rel] = 'self'
    data
  end

  def balance_account_state
    object.balance_account.try(:balance).try(:to_f)
  end

  def income_account_state
    object.income_account.try(:balance).try(:to_f)
  end
end
