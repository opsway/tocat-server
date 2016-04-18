module Actions
  class AuthenticateRequest < Actions::BaseAction
    attr_reader :user

    def initialize(headers: {})
      super()
      @headers = headers
    end

    def call
      detect_user
      self
    end

    private

    attr_reader :headers

    def detect_user
      @user ||= User.find(decoded_auth_token[:user_id]) if decoded_auth_token
      @user || push_errors('Invalid token') && nil
    end

    def decoded_auth_token
      @decoded_auth_token ||= JsonWebToken.decode(http_auth_header) if http_auth_header
    end

    def http_auth_header
      headers['Authorization'].split(' ').last if headers['Authorization'].present?
    end
  end
end