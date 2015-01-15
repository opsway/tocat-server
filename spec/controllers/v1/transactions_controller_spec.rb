require 'rails_helper'

RSpec.describe V1::TransactionsController, type: :controller do

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
      expect(response).to match_response_schema_to_list("transactions")

    end
  end

  describe "/transaction/:id" do
    before(:each) do
      team = create(:team)
      get :show, id: create(:transaction, account: team.balance_account).id, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      expect(response).to match_response_schema("transaction")

    end

  end


end
