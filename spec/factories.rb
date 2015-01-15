require 'factory_girl_rails'

FactoryGirl.define do
  factory :order do
    sequence(:name) { |n| "Order #{n}" }
    team_id 1
    invoiced_budget 10
    free_budget 1
    allocatable_budget 9
    invoice_id 1
    association :team
  end

  factory :team do
    sequence(:name) { |n| "Team #{n}" }
  end

  factory :task_orders do
    task_id 1
    order_id 1
  end

  factory :account do
    account_type ""
    accountable_id 1
    accountable_type "Team"
  end

  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:login) { |n| "usr#{n}" }
    association :team
    daily_rate 50
    role_id 1
  end

  factory :role do
    name "manager"
  end

  factory :transaction do
    total 999
    sequence(:comment) { |n| "Transaction #{n}" }
    account_id 1
    user_id 1
  end
end
