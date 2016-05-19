module Actions
  module Users
    class BaseAuthentication < Actions::BaseAction
      attr_reader :auth_token

      def initialize(user_email:)
        super()
        @user_email = user_email
      end

      def call
        @auth_token = JsonWebToken.encode(user_email: user.email) if user
        self
      end

      private

      attr_reader :user_email

      def user
        user = retrieve_user
        return user if user
        push_errors('invalid credentials')
        nil
      end

      def retrieve_user
        User.find_by(email: @user_email)
      end
    end
  end
end
