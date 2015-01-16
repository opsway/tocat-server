class TeamShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :balance_account_state, :income_account_state

  private

  def balance_account_state
    { total: object.balance_account.balance }
  end

  def income_account_state
    { total: object.income_account.balance }
  end
end
