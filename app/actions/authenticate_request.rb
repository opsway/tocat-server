module Actions
  class AuthenticateRequest < Actions::BaseAction
    attr_reader :user

    def initialize(request: {})
      super()
      @request = request
    end

    def call
      detect_user
      self
    end

    private

    attr_reader :request

    def detect_user
      if decoded_auth_token
        if decoded_auth_token && User.find_by_email(decoded_auth_token[:user_email]).active? ||
           User.find_by_email(decoded_auth_token[:user_email]).active? && User.where(email: decoded_auth_token[:user_email]).exists?

          @user ||= User.find_by_email(decoded_auth_token[:user_email])
        end
      end
      @user || push_errors('Invalid token') && nil
    end

    def decoded_auth_token
      @decoded_auth_token ||= JsonWebToken.decode(http_auth_header) if http_auth_header
    end

    def http_auth_header
      if headers['Authorization'].present?
        headers['Authorization'].split(' ').last
      else
        params[:authorization]
      end
    end

    def authorized_addresses
      Settings.authorized_addresses
    end

    def legacy_auth?
      authorized_addresses.include?(request.remote_ip)
    end

    def headers
      request.headers
    end

    def params
      request.params
    end
  end
end
