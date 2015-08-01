require 'rails_helper'

RSpec.describe InvoicesController, :type => :controller do

  describe "index action" do

    before(:each) do 
      create_list(:invoice, 10)
    end

    it "should get all unfiltered invoices" do
      get 'index'

      expect(JSON.parse(response.body).collect{ |o| o['id']}.sort).to eq(Invoice.all.collect(&:id).sort)
    end

    it 'should get all filtered by total DESC' do
      get :index, {sort: 'total:desc'}

      expect(JSON.parse(response.body).collect{ |o| o['id']}).to eq(Invoice.sorted_by_total('desc').collect(&:id))
    end

  end

  describe 'show action' do

    let(:invoice) { create(:invoice) }
    before(:each) { create_list(:invoice, 100) }

    it 'should get one record' do
      get :show, id: invoice.id
      expect(JSON.parse(response.body)['id']).to eq(invoice.id)
    end

  end

  describe 'create action' do

    it 'should create new record' do
      ext_id = rand(10000)
      post :create, { external_id: ext_id }
      expect(response.code).to eq('201')
      new_invoice = Invoice.where(external_id: ext_id).first
      expect(new_invoice).not_to eq(nil)
    end

    it 'should fail while creating new invalid record' do
      post :create
      expect(response.code).to eq('422')
    end

  end

  describe 'delete action' do

    let(:invoice) { create(:invoice, paid: true) }

    it 'should destroy invoice' do
      delete :destroy, { id: invoice.id }
      expect(response.code).to eq('200')
    end

  end

  describe 'paid actions' do

    it 'should paid invoice' do
      invoice = create(:invoice, paid: false)
      post :set_paid, invoice_id: invoice.id
      expect(response.code).to eq('200')
      expect(invoice.reload.paid).to eq(true)
    end

    it 'should unpaid invoice' do
      invoice = create(:invoice, paid: true)
      delete :delete_paid, invoice_id: invoice.id
      expect(response.code).to eq('200')
      expect(invoice.reload.paid).to eq(false)
    end

  end

end
