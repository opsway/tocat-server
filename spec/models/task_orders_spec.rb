require 'rails_helper'

RSpec.describe TaskOrders, :type => :model do
  it {should validate_presence_of(:task_id)}
  it {should validate_presence_of(:order_id)}
  it {should validate_presence_of(:budget)}
  it {should belong_to(:order)}
  it {should belong_to(:task)}
  it "should fail if budget equals zero " do
    order = build(:task_orders)
    order.budget = 0
    order.valid?
    order.errors.should have_key(:budget)
  end

  it "should fail if budget lowen than zero " do
    order = build(:task_orders)
    order.budget = -10
    order.valid?
    order.errors.should have_key(:budget)
  end
end
