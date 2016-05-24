require 'rails_helper'

require 'google/apis/oauth2_v2/service'
require 'google/apis/oauth2_v2/classes'
require 'google/apis/oauth2_v2/representations'

describe 'request auth token' do
  let(:auth_path) { '/authenticate' }
  let(:resource_path) { '/tasks' }

  context 'when correct code provided' do
    let(:google_code) { 'some_valid_google_code' }

    context 'when user exists' do
      before do
        user = create(:user)
        user_info = double(:user_info, email: user.email)
        allow_any_instance_of(Google::Apis::Oauth2V2::Oauth2Service).to receive(:get_userinfo).and_return(user_info)
      end

      it 'gets valid access token' do
        get auth_path, { code: google_code }
        expect(response.code).to eq('200')
        auth_token = JSON.parse(response.body).fetch('auth_token')

        get resource_path, {}, { 'Authorization' => auth_token }
        expect(response.code).to eq('200')
      end
    end

    context 'when user does not exist' do
      before do
        user_info = double(:user_info, email: 'non_existing_user@example.com')
        allow_any_instance_of(Google::Apis::Oauth2V2::Oauth2Service).to receive(:get_userinfo).and_return(user_info)
      end

      it 'gets 401' do
        get auth_path, { code: google_code }
        expect(response.code).to eq('401')
        errors = JSON.parse(response.body).fetch('errors')

        expect(errors).to eq(['invalid credentials'])
      end
    end
  end

  context 'when incorrect code provided' do
    before do
      allow_any_instance_of(Google::Apis::Oauth2V2::Oauth2Service).to receive(:get_userinfo).and_raise(Signet::AuthorizationError)
    end

    it 'gets 401' do
      get auth_path, { code: 'some_invalid_code' }
      expect(response.code).to eq('401')
    end
  end
end
