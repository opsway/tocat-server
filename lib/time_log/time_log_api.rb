require 'rest-client'

module TimeLog
  class TimeLogApi
    attr_reader :users_worklogs, :success, :error

    TEMPO_API_URL = 'https://opsway.atlassian.net/plugins/servlet/tempo-getWorklog/'
    ZOHO_API_URL = 'https://people.zoho.com/people/api/'
    BASE_URL = 'https://opsway.atlassian.net'

    def initialize(params)
      @params = params
      @parsed_data = []
      @error = ''
      @success = true
      @users_worklogs = {}
      @zoho_data = {}
    end

    def get_worklogs
      self.get_worklogs_for_users
      @success
    end

    protected

    def data_from_tempo_api
      url = "#{TEMPO_API_URL}?baseUrl=#{BASE_URL}&#{self.api_date_params}&tempoApiToken=#{Rails.application.secrets[:tempo_api_key]}"

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

    def data_from_zohopeople_api(username)
      url = "#{ZOHO_API_URL}forms/P_ApplyLeaveView/records?authtoken=#{Rails.application.secrets[:zoho_people_auth]}&searchColumn=EMPLOYEEID&searchValue=#{username}"
      RestClient.get(url)
    end

    def parsing_worklogs(data)
      data.blank? ? {} : Hash.from_xml(data)
    end

    def prepare_worklogs(username)
      prepared_worklogs = []

      @parsed_data.each do |item|
        if username == item['username']
          prepared_worklogs << self.prepare_worklog(item)
        end
      end

      self.group_tempo_worklogs_per_day(prepared_worklogs)
    end

    def prepare_worklog(data)
      {
          user_id: data['username'],
          work_date: data['work_date'],
          issue_key: data['issue_key'],
          hours: data['hours'].to_f.round(1)
      }
    end

    def group_tempo_worklogs_per_day(worklogs)
      group_tempo_worklogs_per_day = []
      grouped_worklogs = worklogs.group_by{ |worklog| worklog[:work_date] }
      # sorted_worklogs_days = grouped_worklogs.keys.sort

      (self.start_date..self.end_date).each do |date|
        str_date = date.to_s(:db)
        zoho_leave = self.get_leave_percentage_per_day(str_date)
        issues = (grouped_worklogs[str_date] || []).map{ |w| w.slice(:issue_key, :hours) }
        total_hours = issues.map{ |w| w[:hours].to_f }.sum.round(1)

        group_tempo_worklogs_per_day << {
            work_date: str_date,
            hours: total_hours,
            leave_type: self.check_approval_status(zoho_leave),
            approval_status: zoho_leave[:approval_status],
            percentage: zoho_leave[:percentage],
            issues: issues
        }
      end

      group_tempo_worklogs_per_day
    end

    def check_approval_status(leave)
      if leave[:approval_status] == 'Rejected' || leave[:approval_status] == 'Cancelled'
        ''
      else
        leave[:leave_type]
      end
    end

    def start_date
      @start_date ||= self.prepare_date(@params[:date_start]).to_date
    end

    def end_date
      @end_date ||= self.prepare_date(@params[:date_end]).to_date
    end

    def prepare_date(date)
      Date.parse(date)
    end

    def get_leave_percentage_per_day(date)
      leaves = {
          leave_type: '',
          approval_status: '',
          percentage: ''
      }

      @zoho_data.each do |data|
        if (data['From'] == data['To'] && prepare_date(data['From']) == prepare_date(date)) ||
           (data['From'] != data['To'] && prepare_date(date).between?(prepare_date(data['From']), prepare_date(data['To'])))
          leaves = {
              leave_type: data['Leave Type'],
              approval_status: data['ApprovalStatus'],
              percentage: data['Days Taken']
          }
          break
        end
      end
      leaves
    end

    def api_date_params
      @api_date_params ||= "dateFrom=#{@params[:date_start]}&dateTo=#{@params[:date_end]}"
    end

    def parsing_zoho_data(raw_data)
      parsed_data = JSON.parse(raw_data)
      parsed_data[0]['message'] == 'No records found' ? [] : parsed_data
    end

    def prepare_zoho_data(username)
      raw_data = self.data_from_zohopeople_api(username)
      self.parsing_zoho_data(raw_data)
    end

    def get_worklogs_for_users
      usernames = @params['user_id'].split(',')
      raw_data = self.data_from_tempo_api
      @parsed_data = self.parsing_worklogs(raw_data).try(:[], 'worklogs').try(:[], 'worklog') || []

      usernames.each do |user|
        @zoho_data = self.prepare_zoho_data(user)
        @users_worklogs[user] = self.prepare_worklogs(user)
      end
    end
  end
end