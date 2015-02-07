class TeamShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :balance_account_state, :income_account_state

  private

  def balance_account_state
    object.balance_account.balance.to_f
  end

  def income_account_state
    object.income_account.balance.to_f
  end
end
