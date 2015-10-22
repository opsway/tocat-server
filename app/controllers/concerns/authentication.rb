module Authentication

  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
    before_filter :authenticate_request!
    rescue_from AuthenticationTimeoutError, with: :authentication_timeout
    rescue_from NotAuthenticatedError, with: :user_not_authenticated
  end

  protected

  def authenticate_request!
    fail NotAuthenticatedError unless login_included_in_auth_token?
    @current_user = User.find_by_login(decoded_auth_token[:login])
  rescue JWT::ExpiredSignature
    raise AuthenticationTimeoutError
  rescue JWT::VerificationError, JWT::DecodeError
    raise NotAuthenticatedError
  end

  private

  def login_included_in_auth_token?
    http_auth_token && decoded_auth_token && decoded_auth_token[:login]
  end

  def decoded_auth_token
    @decoded_auth_token ||= AuthToken.decode(http_auth_token)
  end

  def http_auth_token
    @http_auth_token ||= if request.headers['Authentication'].present?
                           request.headers['Authentication'].split(' ').last
                         end
  end

  def authentication_timeout
    render json: { errors: ['Authentication Timeout'] }, status: 419
  end

  def forbidden_resource
    render json: { errors: ['Not Authorized To Access Resource'] }, status: :forbidden
  end

  def user_not_authenticated
    render json: { errors: ['Not Authenticated'] }, status: :unauthorized
  end
end