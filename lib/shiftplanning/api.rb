require 'singleton'
class ShiftplanningApi
  include Singleton
  attr_reader :errors
  attr_reader :api_error
  attr_reader :api_unavailable

  def initialize
    @last_updated = []
    @users        = []
    begin
      token_handler
    rescue Exception => @api_errors
      offline_mode
    end
  end

  def timesheets
    begin
      @request.reports.timesheets.params = { :start_date => "April 14 15",
                                             :end_date => Date.current.strftime("%B %d %y"),
                                             :type => 'timesheets_summary',
                                             :approval_status => 1}
      response         = @interface.submit(@request.reports.timesheets)
      if response[0][0]['status'].to_i != 1
        api_logger.info("token invalid")
        if token_handler(response)
          response = @interface.submit(@request.reports.timesheets)
          api_logger.info("token still invalid after token_handler") if response[0][0]['status'].to_i != 1
          api_logger.info(response) if response[0][0]['status'].to_i != 1
          api_logger.info("END") if response[0][0]['status'].to_i != 1
        else
          @errors = response[1][0]
          return @errors
        end
      end
      users = []
      response[0][0]['data']['users'].each do |user|
        users << user unless user['shifts'].empty?
      end
      users
    rescue Exception => @api_errors
      offline_mode
      return []
    end
  end

  protected

  def offline_mode
    exception_logger.info "#{Time.now}: Method: #{__method__}. Exception: #{@api_errors}."
    @api_unavailable = true
    time             = Time.now
    if @api_fallback_time != time
      #Duty.destroy_all # Duty removed from repository redmine-support
      @api_fallback_time = time
    end
  end

  LOGFILE = "#{Rails.root}/log/web.sp_api.log"

  def api_logger
    Logger.new(LOGFILE, 7, 2048000)
  end

  def exception_logger
    Logger.new("#{Rails.root}/log/web.exception.log", 7, 2048000)
  end


  def token_handler(response = nil)
    if !response|| response[0][0]['status'].to_i == 3
      key                         = Rails.application.secrets[:shiftplanning_key]
      login                       = Rails.application.secrets[:shiftplanning_login]
      password                    = Rails.application.secrets[:shiftplanning_password]
      @interface                  = SP::Interface.new(key, :verbose => false)
      @request                    = SP::Request.new
      @request.staff.login.params = { :username => login, :password => password }
      response                    = @interface.submit(@request.staff.login)
      true
    else
      false
    end

  end
end
