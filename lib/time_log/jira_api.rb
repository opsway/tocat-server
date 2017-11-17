require 'rest-client'

module TimeLog
  class JiraApi
    attr_reader :issue_data, :success, :message

    JIRA_API_URL = 'https://opsway.atlassian.net/rest/api/2/'

    def initialize(params)
      @params = params
      @message = ''
      @success = true
      @issue_data = {}
    end

    def issues_summary
      self.get_issues_data
      @success
    end

    protected

    def data_from_jira_api(issue_key)
      url = "#{JIRA_API_URL}issue/#{issue_key}"
      response = self.send_api_request(url)
      parsed_data = JSON.parse(response)
      parsed_data['fields']['summary']
    end

    def get_issues_data
      issues_keys = JSON.parse(@params[:issues_keys])
      issues_keys.each do |key|
        @issue_data[key] = {
            summary: self.data_from_jira_api(key)
        }
      end
    end

    def send_api_request(url)
      RestClient.get(url, headers={Authorization: "#{Rails.application.secrets[:jira_authorize]}"}) { |response, request, result, &block|
        case response.code
          when 502
            @success = false
            @message = "Check your connection"
            return nil
          when 401
            @success = false
            @message = "Unauthorized"
            return nil
          when 405
            @success = false
            @message = "Method not Allowed"
            return nil
          when 500
            @success = false
            @message = "Internal Error On API Server"
            return nil
          when 200
            @success = true
            response
          when 404
            @success = false
            @message = "Not Found"
            return nil
          else
            @success = false
            response.return!(request, result, &block)
        end
      }
    end
  end
end