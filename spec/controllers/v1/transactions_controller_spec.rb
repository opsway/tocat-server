require 'rails_helper'

RSpec.describe V1::TransactionsController, :type => :controller do


  describe "/transaction " do

    before(:each) do
      team = create(:team)
      create_list(:transaction, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      sample = @body.sample
      t = Transaction.find sample['id']
      expect(sample["comment"]).to eq t.comment
      expect(sample["links"]["href"]).to eq v1_transaction_path(t)
    end
  end

  describe "/transaction/:id" do
    before(:each) do
      binding.pry
      team = create(:team)
      get :show, id: create(:transaction, :account => team.balance_account).id, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      sample = @body
      t = Transaction.find(sample['id'])
      expect(sample["timestamp"]).to eq t.created_at.to_f
      expect(sample["account"]["id"]).to eq t.account.id
      expect(sample["account"]["type"]).to eq t.account.account_type
      expect(BigDecimal.new(sample["total"])).to eq t.total
      expect(sample["comment"]).to eq t.comment
      expect(sample["user_id"]).to eq t.user_id
    end

  end


end
