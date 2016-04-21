require 'google/apis/oauth2_v2/service'
require 'google/apis/oauth2_v2/classes'
require 'google/apis/oauth2_v2/representations'

module Actions
  module Users
    class GoogleAuthentication < Actions::BaseAction
      attr_reader :auth_token

      def initialize(auth_code:)
        super()
        @auth_code = auth_code
      end

      def call
        @auth_token = JsonWebToken.encode(user_id: user.id) if user
        self
      end

      private

      attr_reader :auth_code

      def user
        @guser ||= retrieve_user
        return @guser if @guser
        push_errors('invalid credentials')
        nil
      end

      def retrieve_user
        credentials = Google::APIClient::ClientSecrets.load(Rails.root.join('config', 'client_secrets.json'))
        auth_client = credentials.to_authorization
        auth_client.update!(
          :scope => 'https://www.googleapis.com/auth/userinfo.email'
        )
        auth_client.code = auth_code

        client = Google::Apis::Oauth2V2::Oauth2Service.new
        client.authorization = auth_client
        info = client.get_userinfo

        User.find_by(email: info.email)
      rescue
        nil
      end
    end
  end
end
