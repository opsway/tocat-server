class UserShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :name,
             :login,
             :team,
             :daily_rate,
             :role,
             :links,
             :balance_account_state,
             :income_account_state

  private

  def team
    data = {}
    data[:name] = object.team.name
    data[:href] = team_path(object.team)
    data
  end

  def role
    object.role.name
  end

  def links
    data = {}
    data[:href] = user_path(object)
    data[:rel] = 'self'
    data
  end

  def attributes
    data = super
    balance = {}
    income = {}
    data
  end

  def balance_account_state
    { total: object.balance_account.balance }
  end

  def income_account_state
    { total: object.income_account.balance }
  end
end
