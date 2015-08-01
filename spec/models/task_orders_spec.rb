require 'rails_helper'

RSpec.describe TaskOrders, type: :model do
  it { should validate_presence_of(:task_id) }
  it { should validate_presence_of(:order_id) }
  it { should validate_presence_of(:budget) }
  it { should belong_to(:order) }
  it { should belong_to(:task) }

  it 'should fail if budget equals zero ' do
    order = build(:task_orders)
    order.budget = 0
    order.valid?
    order.errors.should have_key(:budget)
  end

  it 'should fail if budget lowen than zero ' do
    order = build(:task_orders)
    order.budget = -10
    order.valid?
    order.errors.should have_key(:budget)
  end

  it 'cannot update budget if task accepted and paid' do
    budget = create(:task_orders, budget: 10)
    budget.task.update_attributes(accepted: true, paid: true)
    budget.budget = 11
    budget.save
    expect(budget.errors).to have_key(:budget)
    expect(budget.errors[:budget]).to eq(['Can not update budget for task that is Accepted and paid'])
    expect(budget.reload.budget).to eq(10)
  end

  it 'cannot update budget if order completed' do
    budget = create(:task_orders, budget: 10)
    budget.order.update_attributes(completed: true)
    budget.budget = 11
    budget.save
    expect(budget.errors).to have_key(:budget)
    expect(budget.errors[:budget]).to eq(['Completed order is used in budgets, can not update task'])
    expect(budget.reload.budget).to eq(10)
  end

  it 'cannot update budget teams doesn\'t match' do
    task = create(:task, user: create(:user, team: create(:team)))
    order = create(:order, team: create(:team))
    budget = build(:task_orders, task: task, order: order)
    budget.save
    expect(budget.errors).to have_key(:resolver)
    expect(budget.errors[:resolver]).to eq(['Task resolver is from different team than order'])
    expect(budget.id).to eq(nil)    
  end

  it 'cannot update budget teams doesn\'t match part 2' do
    team = create(:team)
    task = create(:task, user: create(:user, team: team))
    order = create(:order, team: create(:team))
    budget = create(:task_orders, task: task, order: create(:order, team: team))
    order_was = budget.order.id
    task.task_orders << budget
    budget.order = order
    budget.save
    expect(budget.errors).to have_key(:orders)
    expect(budget.errors[:orders]).to eq(['Orders are created for different teams'])
    expect(budget.reload.order.id).to eq(order_was)    
  end

  it 'should validate budget' do
    budget = create(:task_orders)
    budget_value = budget.budget
    budget.budget = budget.order.free_budget + 100
    budget.save
    expect(budget.errors).to have_key(:budget)
    expect(budget.errors[:budget]).to eq(['You can not assign more budget than is available on order'])
    expect(budget.reload.budget).to eq(budget_value)
  end

  it 'should increase order free budget after budget deleting' do
    budget = create(:task_orders)
    order = budget.order
    free_budget_before = order.free_budget
    budget.destroy
    expect(order.reload.free_budget).to eq(free_budget_before + budget.budget)
  end

  it 'should decrease order free budget after budget creating' do
    order = create(:order)
    free_budget_before = order.free_budget
    budget = create(:task_orders, order: order)
    expect(order.reload.free_budget).to eq(free_budget_before - budget.budget)
  end

  it 'should decrease order free budget after budget updating' do
    budget = create(:task_orders)
    order = budget.order
    free_budget_before = order.reload.free_budget
    budget.update_attributes!(budget: budget.budget + 1)
    expect(order.reload.free_budget).to eq(free_budget_before - 1)
  end
end
