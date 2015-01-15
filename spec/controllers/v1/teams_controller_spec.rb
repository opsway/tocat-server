require 'rails_helper'

RSpec.describe V1::TeamsController, :type => :controller do

  describe "/team " do

    before(:each) do
      create_list(:team, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "return valid names" do
      db_names = Team.all.map { |o| o.name}
      names = @body.map { |m| m["name"] }
      expect(names).to match_array(db_names)
    end

    it "should check JSON schema" do
      sample = @body.sample
      team = Team.find sample['id']
      expect(sample["name"]).to eq team.name
      expect(sample["links"]["href"]).to eq v1_team_path(team)
    end
  end

  describe "/team/:id" do
    before(:each) do
      team = create(:team)
      get :show, id: team.id, format: :json
      @body = JSON.parse(response.body)
    end

    it "returns a successful 200 response" do
      expect(response).to be_success
    end

    it "should check JSON schema" do
      sample = @body
      team = Team.find(sample['id'])
      expect(sample["name"]).to eq team.name
      expect(sample["balance_account"]["id"]).to eq team.balance_account.id
      expect(BigDecimal.new(sample["balance_account"]["balance"])).to eq team.balance_account.balance
      expect(sample["balance_account"]["href"]).to eq v1_team_balance_path(team)
      expect(sample["income_account"]["id"]).to eq team.income_account.id
      expect(BigDecimal.new(sample["income_account"]["balance"])).to eq team.income_account.balance
      expect(sample["income_account"]["href"]).to eq v1_team_income_path(team)
    end

  end

  describe "accounts" do
    before(:each) do
      @team = create(:team)
    end

    it "validates balance account JSON schema" do
      get :balance_account, id: @team.id, format: :json
      body = JSON.parse(response.body)
      account = @team.balance_account
      expect(body["type"]).to eq account.account_type
      expect(BigDecimal.new(body["balance"])).to eq account.balance
      expect(body["parent"]["id"]).to eq account.accountable.id
      expect(body["parent"]["type"]).to eq account.accountable.class.name
    end

    it "validates income account JSON schema" do
      get :income_account, id: @team.id, format: :json
      body = JSON.parse(response.body)
      account = @team.income_account
      expect(body["type"]).to eq account.account_type
      expect(BigDecimal.new(body["balance"])).to eq account.balance
      expect(body["parent"]["id"]).to eq account.accountable.id
      expect(body["parent"]["type"]).to eq account.accountable.class.name
    end

  end
end
