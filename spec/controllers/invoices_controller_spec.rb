require 'rails_helper'

RSpec.describe InvoicesController, :type => :controller do

  describe '/invoice' do

    it 'returns a successful 200 response' do
      create_list(:invoice, 5)
      get :index, format: :json
      expect(response).to be_success
    end

    it 'return a successful 201 response' do
      post :create, external_id: 'test invoice'
      expect(response.status).to eq(201)
    end
    it 'return 422 response' do
      post :create, external_id: ''
      expect(response.status).to eq(422)
    end

  end

  describe '/invoice/:id' do
    it 'action show return a response' do
      invoice = create(:invoice)
      get :show, id: invoice.id, format: :json
      # expect(response).to match_response_schema('invoice')
      expect(response.status).to eq(200)
    end

    it 'action destroy return 200 response' do
      invoice = create(:invoice)
      delete :destroy, id: invoice.id
      expect(response.status).to eq(200)
    end

    it 'really delete invoice' do
      invoice = create(:invoice)
      delete :destroy, id: invoice.id
      expect(assigns(:invoice).destroyed?).to be true
    end

    it 'return 422 response' do
      invoice = create(:invoice_with_orders)
      # order = create(:order)
      # invoice.orders << order
      delete :destroy, id: invoice.id
      expect(response.status).to eq(422)
    end
  end

    describe '/invoice/:invoice_id/paid' do
      it 'return 200 responce in the set_paid action' do
        invoice = create(:invoice)
        post :set_paid, invoice_id: invoice.id
        expect(response.status).to eq(200)
      end

      it 'return 200 responce at the delete_paid action' do
        invoice = create(:invoice)
        delete :delete_paid, invoice_id: invoice.id
        expect(response.status).to eq(200)
      end

      # it 'return 422 responce in the set_paid action' do
      #   invoice = create(:invoice)
      #   post :set_paid, invoice_id: invoice.id
      #   expect(response.status).to eq(422)
      #end
    end
end
