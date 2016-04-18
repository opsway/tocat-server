class AuthenticationController < ApplicationController
  skip_before_action :authenticate_user!

  def authenticate
    action = Actions::Users::BaseAuthentication.new(user_id: params[:user_id]).call
    if action.success?
      render json: { auth_token: action.auth_token }
    else
      render json: { errors: action.errors }, status: :unauthorized
    end
  end
end
