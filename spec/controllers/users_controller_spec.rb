require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '/user ' do
    before(:each) do
      create_list(:user, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema_to_list('users')
    end
  end

  describe '/user/:id' do
    before(:each) do
      get :show, id: create(:user).id, format: :json
      @body = JSON.parse(response.body)
      @response = response
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema('user')
    end
  end

  describe 'accounts' do
    before(:each) do
      @user = create(:user)
      @user.balance_account.transactions << create(:transaction)
      @user.income_account.transactions << create(:transaction)
    end

    it 'validates balance account JSON schema' do
      get :balance_account, id: @user.id, format: :json
      expect(response).to match_response_schema('account')
    end

    it 'validates income account JSON schema' do
      get :income_account, id: @user.id, format: :json
      expect(response).to match_response_schema('account')
    end
  end
end
