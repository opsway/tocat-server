require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '/users ' do

    it 'should check JSON schema' do
      get :index, format: :json
      expect(response).to match_response_schema('users')
    end

    it 'create new user' do
      a = User.count
      post :create, helpers_params(build(:user).attributes)
      expect(User.count).to eq(a + 1)
    end

    it 'return a successful 201 response' do
      post :create, helpers_params(build(:user).attributes)
      expect(response.status).to eq(201)
    end

    it 'return 406 response' do
      post :create, build(:user).attributes
      expect(response.status).to eq(406)
    end

   end

  describe '/user/:id' do
    before(:each) do
      @user = create(:user)
    end
    # it 'returns a successful 200 response' do
    #   expect(response).to be_success
    # end

    it 'successful update user' do
      patch :update, id: @user, name: "Jon"
      expect(response).to be_success
      expect(@user.reload.name).to eq("Jon")
    end

    it 'return 406 response' do
      patch :update, id: @user, team: {id: nil}
      expect(response.status).to eq(406)
    end

    it 'successfully add payment' do
      expect_any_instance_of(User).to receive(:add_payment).with("test comment", '100')
      post :add_payment, user_id: @user.id, comment: "test comment", total: 100
    end

    it 'successfully pay bonus' do
      expect_any_instance_of(User).to receive(:paid_bonus).with(100.0, 20.0)
      post :pay_bonus, user_id: @user.id, bonus: 20, income: 100
    end

    it 'return 404 response' do
      patch :update, id: 0
      expect(response.status).to eq(404)
    end

    it 'should check JSON schema' do
      get :show, id: @user.id
      expect(response).to match_response_schema('user')
    end
  end
end
