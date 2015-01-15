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
      sample = @body.sample
      t = User.find sample['id']
      expect(sample["name"]).to eq t.name
      expect(sample["login"]).to eq t.login
      expect(sample["team"]["name"]).to eq t.team.name
      expect(sample["team"]["href"]).to eq v1_team_path(t.team)
      expect(sample["role"]).to eq t.role.name
      expect(sample["links"]["href"]).to eq v1_user_path(t)
      expect(sample["links"]["rel"]).to eq "self"
    end
  end

  describe "/user/:id" do
    before(:each) do
      get :show, id: create(:user).id, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      sample = @body
      t = User.find(sample['id'])
      expect(sample["name"]).to eq t.name
      expect(sample["login"]).to eq t.login
      expect(sample["team"]["name"]).to eq t.team.name
      expect(sample["team"]["href"]).to eq v1_team_path(t.team)
      expect(BigDecimal.new(sample["daily_rate"])).to eq t.daily_rate
      expect(sample["role"]).to eq t.role.name
      expect(sample["links"]["href"]).to eq v1_user_path(t)
      expect(sample["links"]["rel"]).to eq "self"
      expect(sample["balance_account"]["href"]).to eq v1_user_balance_path(t)
      expect(sample["balance_account"]["id"]).to eq t.balance_account.id
      expect(sample["income_account"]["href"]).to eq v1_user_income_path(t)
      expect(sample["income_account"]["id"]).to eq t.income_account.id
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
