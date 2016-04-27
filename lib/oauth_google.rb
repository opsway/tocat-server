require 'google/apis/oauth2_v2/service'
require 'google/apis/oauth2_v2/classes'
require 'google/apis/oauth2_v2/representations'

class OauthGoogle
  SECRETS_FILE = Rails.root.join('config', 'google_app_secrets.json')
  SCOPE = 'https://www.googleapis.com/auth/userinfo.email'

  def initialize(secrets_file: nil, code: nil, redirect_uri: )
    @secrets_file = secrets_file || SECRETS_FILE
    @code = code
    @redirect_uri = redirect_uri
  end

  def authorization_uri
    auth_client.authorization_uri.to_s
  end

  def user_email
    user_info.email
  end

  private

  attr_reader :secrets_file, :code
  attr_reader :redirect_uri

  def user_info
    @user_info ||= client.get_userinfo
  end

  def credentials
    Google::APIClient::ClientSecrets.load(secrets_file)
  end

  def auth_client
    client = credentials.to_authorization
    client.update!(
      scope: SCOPE,
      redirect_uri: redirect_uri
    )
    client.code = code
    client
  end

  def client
    client = Google::Apis::Oauth2V2::Oauth2Service.new
    client.authorization = auth_client
    client
  end
end
