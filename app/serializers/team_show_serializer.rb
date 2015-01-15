class TeamShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name

  def attributes
    data = super
    data[:balance_account] = {:id => object.balance_account.id,
                              :balance => object.balance_account.balance,
                              :href => v1_team_balance_path(object)}
    data[:income_account] = {:id => object.income_account.id,
                              :balance => object.income_account.balance,
                              :href => v1_team_income_path(object)}
    data[:links] = [{:href => v1_team_balance_path(object), :rel => 'balance'},
                    {:href => v1_team_income_path(object), :rel => 'income'}]
    data
  end
end
