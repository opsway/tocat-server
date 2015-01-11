require 'factory_girl_rails'

FactoryGirl.define do
  factory :order do
    name "Test Order"
    team_id 1
    invoiced_budget 10
    allocatable_budget 9
  end

  factory :team do
    name "Test Team"
    balance_account_id 1
    gross_profit_account 1
  end

  factory :task_orders do
    task_id 1
    order_id 1
  end

  factory :account do
    account_type ""
  end
end
