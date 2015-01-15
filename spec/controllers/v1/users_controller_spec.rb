require 'rails_helper'

RSpec.describe V1::UsersController, type: :controller do


  describe "/user " do

    before(:each) do
      user = create(:user)
      create_list(:user, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      expect(response).to match_response_schema_to_list("users")
    end
  end

  describe "/user/:id" do
    before(:each) do
      get :show, id: create(:user).id, format: :json
      @body = JSON.parse(response.body)
      @response = response
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      expect(response).to match_response_schema("user")
    end

  end

  describe "accounts" do
    before(:each) do
      @user = create(:user)
    end

    it "validates balance account JSON schema" do
      get :balance_account, id: @user.id, format: :json
      body = JSON.parse(response.body)
      account = @user.balance_account
      expect(body["type"]).to eq account.account_type
      expect(BigDecimal.new(body["balance"])).to eq account.balance
      expect(body["parent"]["id"]).to eq account.accountable.id
      expect(body["parent"]["type"]).to eq account.accountable.class.name
    end

    it "validates income account JSON schema" do
      get :income_account, id: @user.id, format: :json
      body = JSON.parse(response.body)
      account = @user.income_account
      expect(body["type"]).to eq account.account_type
      expect(BigDecimal.new(body["balance"])).to eq account.balance
      expect(body["parent"]["id"]).to eq account.accountable.id
      expect(body["parent"]["type"]).to eq account.accountable.class.name
    end

  end


end
