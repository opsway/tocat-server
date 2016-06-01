require 'google/apis/oauth2_v2/service'
require 'google/apis/oauth2_v2/classes'
require 'google/apis/oauth2_v2/representations'

module Actions
  module Users
    class GoogleAuthentication < Actions::BaseAction
      attr_reader :auth_token

      def initialize(user_info_provider: )
        super()
        @user_info_provider = user_info_provider
      end

      def call
        @auth_token = JsonWebToken.encode(user_email: user.email) if user
        self
      end

      private

      attr_reader :user_info_provider

      def user
        @guser ||= retrieve_user
        return @guser if @guser
        push_errors('invalid credentials')
        nil
      end

      def retrieve_user
        User.find_by(email: user_info_provider.user_email)
      rescue
        nil
      end
    end
  end
end
