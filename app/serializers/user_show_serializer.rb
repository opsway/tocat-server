class UserShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :login,
             :tocat_team,
             :daily_rate,
             :tocat_server_role,
             :links,
             :accounts,
             :active,
             :coach,
             :balance_account_state,
             :email,
             :income_account_state,
             :tocat_role_id,
             :permissions
           

  private
  
  def tocat_role_id
    object.tocat_role.try(:id)
  end

  def daily_rate
    object.daily_rate.to_f
  end
  
  def permissions
    object.tocat_role.try(:permissions) || []
  end

  def tocat_team
    data = {}
    data[:name] = object.team.name
    data[:href] = team_path(object.team)
    data[:id] = object.team.id
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

  def accounts
    data = {}
    data[:balance] = {id: object.balance_account.try(:id)}
    data[:income] = {id: object.income_account.try(:id)}
    data
  end

  def balance_account_state
    object.balance_account.try(:balance).to_f
  end

  def income_account_state
    object.income_account.try(:balance).to_f
  end
end
