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

    it 'returns a 404 response for nonexisting task' do
      get :show, id: rand(10000)
      expect(response.code).to  eq('404')
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

  describe 'actions' do
    it 'should set accepted for task' do
      task = create(:task)
      post :set_accepted, task_id: task.id
      expect(task.reload.accepted).to eq true
    end

    it 'should delete accepted for task' do
      task = create(:task, accepted: true)
      delete :delete_accepted, task_id: task.id
      task.reload
      expect(task.accepted).to eq false
    end

    it 'should set resolver for task' do
      task = create(:task)
      user = create(:user)
      post :set_resolver, user_id: user.id, task_id: task.id
      expect(task.reload.resolver).to eq user
    end

    it 'should fail on setting non existing user as resolver' do
      task = create(:task, user_id: nil)
      post :set_resolver, user_id: 99, task_id: task.id
      expect(task.reload.resolver).to eq nil
    end

    it 'should delete resolver for task' do
      task = create(:task, user_id: create(:user))
      delete :delete_resolver, task_id: task.id
      task.reload
      expect(task.resolver).to eq nil
    end

    it 'should set budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      params = [{ order_id: order.id, budget: 10 }]
      post :set_budgets, _json: params, task_id: task.id, format: :json
      expect(task.budget).to eq 10
    end

    it 'should update budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      task_order = create(:task_orders, task: task, order: order, budget: 1)
      params = [{ order_id: order.id, budget: 10 }]
      post :set_budgets, _json: params, task_id: task.id, format: :json
      expect(task.budget).to eq 10
    end

    it 'should get budgets for task' do
      task = create(:task)
      order = create(:order, invoiced_budget: 100, allocatable_budget: 10)
      create(:task_orders, task: task, order: order)
      get :budgets, task_id: task.id
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
      get :orders, task_id: task.id
      expect(response).to match_response_schema_to_list('orders')
    end

    it 'should request review' do
      task = create(:task, review_requested: false)
      post :handle_review_request, task_id: task.id
      expect(task.reload.review_requested).to eq(true)
    end

    it 'should cancel review request' do
      task = create(:task, review_requested: true)
      delete :handle_review_request, task_id: task.id
      expect(task.reload.review_requested).to eq(false)
    end

  end

end
