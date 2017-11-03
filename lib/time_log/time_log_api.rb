require 'rest-client'

module TimeLog
  class TimeLogApi
    attr_reader :users_worklogs, :success, :error

    API_URL = 'https://opsway.atlassian.net/plugins/servlet/tempo-getWorklog/'
    REQUEST_PARAMS = 'format=xml&diffOnly=false'
    BASE_URL = 'https://opsway.atlassian.net'

    def initialize(params)
      @params = params
      @error = ''
      @success = true
      @users_worklogs = {}
    end

    def get_worklogs
      self.get_worklogs_for_users
      @success
    end

    protected

    def request_data_from_api(username)
      url = "#{API_URL}?baseUrl=#{BASE_URL}&#{REQUEST_PARAMS}&tempoApiToken=#{Rails.application.secrets[:tempo_api_key]}&userName=#{username}&#{self.api_date_params}"

      RestClient.get(url, {timeout: 20}) { |response, request, result, &block|
        case response.code
          when 502
            @success = false
            @error      = "Check your connection"
            return nil
          when 401
            @success = false
            @error      = "Unauthorized"
            return nil
          when 500
            @success = false
            @error      = "Internal Error On API Server"
            return nil
          when 200
            @success = true
            response
          when 404
            @success = false
            @error      = "Not Found"
            return nil
          else
            @success = false
            response.return!(request, result, &block)
        end
      }
    end

    def parsing_worklogs(data)
      data.blank? ? {} : Hash.from_xml(data)
    end

    def prepare_worklogs(username)
      prepared_worklogs = []
      raw_data = self.request_data_from_api(username)
      parsed_data = self.parsing_worklogs(raw_data).try(:[], 'worklogs').try(:[], 'worklog') || []
      parsed_data.each do |item|
        prepared_worklogs << self.prepare_worklog(item)
      end

      self.group_worklogs_per_day(prepared_worklogs)
    end

    def prepare_worklog(data)
      {
          user_id: data['username'],
          work_date: data['work_date'],
          issue_key: data['issue_key'],
          hours: data['hours'].to_f.round(1)
      }
    end

    def group_worklogs_per_day(worklogs)
      group_worklogs_per_day = []
      grouped_worklogs = worklogs.group_by{ |worklog| worklog[:work_date] }
      sorted_worklogs_days = grouped_worklogs.keys.sort

      sorted_worklogs_days.each do |date|
        issues = grouped_worklogs[date].map{ |w| w.slice(:issue_key, :hours) }
        total_hours = issues.map{ |w| w[:hours].to_f }.sum

        group_worklogs_per_day << {
            work_date: date,
            hours: total_hours,
            leave_type: '',
            percentage: '',
            issues: issues
        }
      end

      group_worklogs_per_day
    end

    def api_date_params
      @api_date_params ||= "dateFrom=#{@params[:date_start]}&dateTo=#{@params[:date_end]}"
    end

    def get_worklogs_for_users
      usernames = @params['user_id'].split(',')
      usernames.each do |user|
        # @zoho_data = self.zoho_api(user)
        @users_worklogs[user] = self.prepare_worklogs(user)
      end
    end
  end
end