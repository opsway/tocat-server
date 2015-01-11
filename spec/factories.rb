require 'factory_girl_rails'

FactoryGirl.define do
  factory :order do
    name "Test Order"
    team_id 1
    invoiced_budget 10
    allocatable_budget 9
  end
end
