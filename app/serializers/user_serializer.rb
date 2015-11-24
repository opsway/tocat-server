class UserSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :login, :team, :role, :links, :balance_account_state, :income_account_state, :active, :daily_rate

  private

  def team
    data = {}
    team = object.team
    data[:id] = team.id
    data[:name] = team.name
    data[:href] = team_path(team)
    data
  end

  def role
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
    object.balance_account.balance.to_f
  end

  def income_account_state
    object.income_account.balance.to_f
  end
end
