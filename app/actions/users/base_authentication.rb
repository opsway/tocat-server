module Actions
  module Users
    class BaseAuthentication < Actions::BaseAction
      attr_reader :auth_token

      def initialize(user_id:)
        super()
        @user_id = user_id
      end

      def call
        @auth_token = JsonWebToken.encode(user_id: user.id) if user
        self
      end

      private

      attr_reader :user_id

      def user
        user = retrieve_user
        return user if user
        push_errors('invalid credentials')
        nil
      end

      def retrieve_user
        User.find_by(id: user_id.to_i)
      end
    end
  end
end
