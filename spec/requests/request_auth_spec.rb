require 'rails_helper'

describe 'User auth on request' do
  let(:request_path) { '/tasks' }

  context 'no token provided' do
    it 'gets 401' do
      get request_path, {}, {}
      expect(response.code).to eq('401')
    end
  end

  context 'when invalid token provided' do
    it 'gets 401' do
      get request_path, {}, { 'Authorization' => 'some_random_string' }
      expect(response.code).to eq('401')
    end
  end

  context 'when valid token provided' do
    let(:token) { JsonWebToken.encode(user_id: create(:user).id) }

    it 'gets 200' do
      get request_path, {}, { 'Authorization' => token }
      expect(response.code).to eq('200')
    end
  end
end
