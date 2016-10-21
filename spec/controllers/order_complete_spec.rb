require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
	let(:user1) { FactoryGirl.build(:user, role_id: 1, team_id: team1.id) }
	let(:user2) { FactoryGirl.build(:user, role_id: 2, team_id: team1.id) }
	let(:user3) { FactoryGirl.build(:user, role_id: 1, coach: true, team_id: team2.id) }
	let(:user4) { FactoryGirl.build(:user, role_id:2, team_id: team2.id) }

	let(:team1) { FactoryGirl.build(:team, parent_id: 1) }
	let(:team2) { FactoryGirl.build(:team, parent_id: team1.id) }

	let(:task1) { FactoryGirl.build(:task, user_id: user1.id) }
	let(:task2) { FactoryGirl.build(:task, user_id: user3.id) }

	let(:order_task) { FactoryGirl.build(:task_orders, task_id: task1.id, order_id: order.id, budget: 500) }
	let(:order_task) { FactoryGirl.build(:task_orders, task_id: task2.id, order_id: order.id, budget: 500) }

  	let(:invoice) { FactoryGirl.build(:invoice) }
  	let(:order) { FactoryGirl.build(:order) }

  	describe 'POST /order' do
	    it 'create order with valid params' do
	      order = order
	      team = {}
	      team[:id] = order[:team_id]
	      order[:team] = team
	      team = create(:team)
	      order[:team_id] = team.id
	      post :create, order, format: :json
	      expect(Order.where(name: order[:name]).exists?).to eq true
	    end

	    it 'create order with invalid params' do
	      valid_order = order
	      order[:team_id] = nil
	      post :create, order: order, format: :json
	      expect(Order.where(id: JSON.parse(response.body)['id']).exists?).to eq false
	    end
	end

    describe 'actions' do

	    it 'should set paid status' do
	      post :set_paid, id: order.id, format: :json
	      expect(Order.find(order.id).paid).to eq true
	    end

	    it 'should set unpaid status' do
	      delete :set_unpaid, id: order.id, format: :json
	      expect(Order.find(order.id).paid).to eq false
	    end

	    it 'should set invoice' do
	      pending
	      post :set_invoice, id: order.id, params: { invoice_id: invoice.id }, format: :json
	      expect(Order.find(order.id).paid).to eq true
	    end

	    it 'should remove invoice' do
	      delete :delete_invoice, id: order.id, format: :json
	      expect(Order.find(order.id).invoice_id).to eq nil
	    end
	end

   	describe 'Set order comlete' do

	  it 'return success on compleate' do
	    post :order_compleate, id: order.id, format: :json
	   	expect(response.status).to be_success
	  end
	end
end