require 'google/api_client/client_secrets'

class AuthenticationController < ApplicationController
  skip_before_action :authenticate_user!

  def authenticate
    if params[:code]
      action = Actions::Users::GoogleAuthentication.new(auth_code: params[:code]).call
      if action.success?
        render json: { auth_token: action.auth_token }
      else
        render json: { errors: action.errors }, status: :unauthorized
      end
    else
      credentials = Google::APIClient::ClientSecrets.load(Rails.root.join('config', 'client_secrets.json'))
      auth_client = credentials.to_authorization
      auth_client.update!(
        :scope => 'https://www.googleapis.com/auth/userinfo.email'
      )
      render json: { url: auth_client.authorization_uri.to_s }
    end
  end
end
