require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  describe '/order' do
    before(:each) do
      create_list(:order, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'return valid names' do
      db_names = Order.all.map(&:name)
      names = @body.map { |m| m['name'] }
      expect(names).to match_array(db_names)
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema_to_list('orders')
    end
  end

  describe 'GET /order/:id' do
    before(:each) do
      order = create(:order)
      get :show, id: order.id
      @body = JSON.parse response.body
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema('order')
    end
  end

  describe 'POST /order' do
    it 'create order with valid params' do
      order = FactoryGirl.attributes_for(:order)
      team = {}
      team[:id] = order[:team_id]
      order[:team] = team
      team = create(:team)
      order[:team_id] = team.id
      post :create, order, format: :json
      expect(Order.where(name: order[:name]).exists?).to eq true
    end

    it 'create order with invalid params' do
      order = FactoryGirl.attributes_for(:order)
      order[:team_id] = nil
      post :create, order: order, format: :json
      expect(Order.where(id: JSON.parse(response.body)['id']).exists?).to eq false
    end
  end

  it 'should delete order' do
    order = create(:order)
    delete :destroy, id: order.id, format: :json
    expect(Order.count).to eq 0
  end

  it 'should update order' do
    order = create(:order)
    patch :update, id: order.id, order: { name: 'New name' }, format: :json
    expect(Order.find(order.id).name).to eq 'New name'
  end

  describe 'actions' do
    before(:each) { @order = create(:order) }

    it 'should set paid status' do
      post :set_paid, id: @order.id, format: :json
      expect(Order.find(@order.id).paid).to eq true
    end

    it 'should set unpaid status' do
      delete :set_unpaid, id: @order.id, format: :json
      expect(Order.find(@order.id).paid).to eq false
    end

    it 'should set invoice' do
      pending
      post :set_invoice, id: @order.id, params: { invoice_id: 1 }, format: :json
      expect(Order.find(@order.id).paid).to eq true
    end

    it 'should remove invoice' do
      delete :delete_invoice, id: @order.id, format: :json
      expect(Order.find(@order.id).invoice_id).to eq nil
    end

    it 'should create suborder' do
      pending
    end

    it 'should get suborders' do
      sub_order = create(:order, parent_id: @order.id)
      @order.sub_orders << sub_order
      get :suborders, id: @order.id, format: :json
      data = JSON.parse response.body
      expect(data[0]['name']).to eq sub_order.name
    end
  end
end
