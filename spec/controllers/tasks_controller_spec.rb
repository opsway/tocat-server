require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  describe '/task' do
    before(:each) do
      create_list(:task, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema_to_list('tasks')
    end
  end

  describe 'GET /task/:id' do
    before(:each) do
      get :show, id: create(:task).id
      @body = JSON.parse response.body
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema('task')
    end
  end
  describe 'POST /task' do
    it 'create task with valid params' do
      task = FactoryGirl.attributes_for(:task)
      post :create, external_id: task[:external_id], format: :json
      expect(Task.where(external_id: task[:external_id]).exists?).to eq true
    end

    it 'create task with invalid params' do
      post :create, {}, format: :json
      expect(Task.all.length).to eq 0
    end
  end

  it 'should delete task' do
    task = create(:task)
    delete :destroy, id: task.id, format: :json
    expect(Task.count).to eq 0
  end

  it 'should update task' do
    task = create(:task)
    patch :update, id: task.id, external_id: 'new id', format: :json
    expect(Task.find(task.id).external_id).to eq 'new id'
  end

  it 'should fail on updating task with invalid params' do
    task = create(:task)
    patch :update, id: task.id, external_id: nil, format: :json
    expect(Task.find(task.id)).to eq task
  end

  describe 'actions' do
    it 'should set accepted for task' do
      task = create(:task)
      post :set_accepted, id: task.id
      expect(task.reload.accepted).to eq true
    end

    it 'should delete accepted for task' do
      task = create(:task, accepted: true)
      delete :delete_accepted, id: task.id
      task.reload
      expect(task.accepted).to eq false
    end

    it 'should set resolver for task' do
      task = create(:task)
      user = create(:user)
      post :set_resolver, user_id: user.id, id: task.id
      expect(task.reload.resolver).to eq user
    end

    it 'should fail on setting non existing user as resolver' do
      task = create(:task, user_id: nil)
      post :set_resolver, user_id: 99, id: task.id
      expect(task.reload.resolver).to eq nil
    end

    it 'should delete resolver for task' do
      task = create(:task, user_id: create(:user))
      delete :delete_resolver, id: task.id
      task.reload
      expect(task.resolver).to eq nil
    end

    it 'should set budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      params = [{ order_id: order.id, budget: 10 }]
      post :set_budgets, _json: params, id: task.id, format: :json
      expect(task.budget).to eq 10
    end

    it 'should update budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      task_order = create(:task_orders, task: task, order: order, budget: 1)
      params = [{ order_id: order.id, budget: 10 }]
      post :set_budgets, _json: params, id: task.id, format: :json
      expect(task.budget).to eq 10
    end

    it 'should get budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      create(:task_orders, task: task, order: order)
      create(:task_orders, task: task, order: order)
      create(:task_orders, task: task, order: order)
      get :budgets, id: task.id
      expect(response).to match_response_schema_to_list('budgets')
    end

    it 'should get budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      order1 = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      order2 = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      create(:task_orders, task: task, order: order)
      create(:task_orders, task: task, order: order1)
      create(:task_orders, task: task, order: order2)
      get :orders, id: task.id
      expect(response).to match_response_schema_to_list('orders')
    end

  end

end
