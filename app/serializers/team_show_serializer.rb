class TeamShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :balance_account, :income_account, :links

  private

  def balance_account
   { id: object.balance_account.id,
     balance: object.balance_account.balance,
     href: v1_team_balance_path(object) }
  end

  def income_account
    { id: object.income_account.id,
      balance: object.income_account.balance,
      href: v1_team_income_path(object) }
  end

  def links
    [ { href: v1_team_balance_path(object), rel: 'balance' },
                    { href: v1_team_income_path(object), rel: 'income' } ]
  end
end
