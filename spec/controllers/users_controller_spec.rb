require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe '/users ' do
   it "create new user" do
     a = User.count
     post :create, helpers_params(build(:user).attributes)

     expect(User.count).to eq(a + 1)
   end
  end

  # describe '/user/:id' do
  #   before(:each) do
  #     get :show, id: create(:user).id, format: :json
  #     @body = JSON.parse(response.body)
  #     @response = response
  #   end
  #
  #   it 'returns a successful 200 response' do
  #     expect(response).to be_success
  #   end
  #
  #   it 'should check JSON schema' do
  #     expect(response).to match_response_schema('user')
  #   end
  # end
end
