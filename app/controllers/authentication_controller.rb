require 'google/api_client/client_secrets'

class AuthenticationController < ApplicationController
  skip_filter :authenticate_user!

  def authenticate
    if params[:code]
      action = Actions::Users::GoogleAuthentication.new(user_info_provider: user_info_provider).call
      if action.success?
        render json: { auth_token: action.auth_token }
      else
        render json: { errors: action.errors }, status: :unauthorized
      end
    else
      render json: { url: user_info_provider.authorization_uri }
    end
  end

  private

  def user_info_provider
    OauthGoogle.new(code: params[:code], redirect_uri: authenticate_url)
  end
end
