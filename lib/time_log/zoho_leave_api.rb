require 'rest-client'

module TimeLog
  class ZohoLeaveApi
    attr_reader :message, :leave_status, :error

    ZOHO_API_URL = 'https://people.zoho.com/people/api/'
    GET_EMPOYEES = 'forms/P_EmployeeView/records'
    GET_LEAVES = 'forms/P_ApplyLeaveView/records'
    CREATE_LEAVE = 'leave/records'
    APPROVE_LEAVE = 'approveRecord'


    def initialize(params)
      @params = params
      @error = ''
      @leave_status = true
      @message = ''
    end

    def create_leave
      self.check_existing_leave
      @leave_status
    end

    def zoho_approved_transactions
      # user_id = self.parse_username(@params[:user_id])
      self.create_transactions(@params[:user_id])
      @leave_status
      @message = 'success'
    end

    protected

    def fetch_user_leaves(username)
      url = "#{ZOHO_API_URL}#{GET_LEAVES}?authtoken=#{Rails.application.secrets[:zoho_people_auth]}&searchColumn=EMPLOYEEID&searchValue=#{username}"
      RestClient.get(url)
    end

    def check_existing_leave
      leaves = self.fetch_user_leaves(@params['user_id'])
      parsed_leaves = self.parsing_zoho_data(leaves)

      parsed_leaves.each do |leave|
        if prepare_date(leave['From']) == prepare_date(leave['To']) && (prepare_date(leave['From']) || prepare_date(leave['To'])) == prepare_date(@params['date'])
          if leave['ApprovalStatus'] == 'Approved'
            @message = 'Leave already approved in ZohoPeople, please check!'
            break
          end

          if leave['ApprovalStatus'] == 'Pending'
            self.reject_leave(leave['recordId'])
            self.create_paid_leave
            @message = 'success'
            break
          end

          self.create_paid_leave
          @message = 'success'
          break
        else
          self.create_paid_leave
          @message = 'success'
          break
        end
      end
    end

    def create_paid_leave
      employee_id = self.get_employee_id(@params['user_id'])
      leave_type_id = self.get_leave_type_id(@params['leave_type'])

      data = "&xmlData=<Request><Record><field name='Employee_ID'>#{employee_id}</field><field name='To'>#{@params['date']}</field><field name='From'>#{@params['date']}</field><field name='Leavetype'>#{leave_type_id}</field><days><date name='#{@params['date']}'>#{@params['percentage'].to_f}</date></days></Record></Request>"

      url = "#{ZOHO_API_URL}#{CREATE_LEAVE}?authtoken=#{Rails.application.secrets[:zoho_people_auth]}#{data}"
      request = JSON.parse(RestClient.post(url, {timeout: 10}))

      if @params['leave_type'] == 'Day off/Vacation'
        self.approve_created_leave((request['pkId']).to_i)
      end

      if @params['leave_type'] == 'Working'
        self.create_transactions(@params['user_id'])
      end

      if @params['leave_type'] == 'Sick [Paid]'
        self.approve_created_leave((request['pkId']).to_i)
        self.create_transactions(@params['user_id'])
      end
    end

    def reject_leave(leave_id)
      url = "#{ZOHO_API_URL}#{APPROVE_LEAVE}?authtoken=#{Rails.application.secrets[:zoho_people_auth]}&pkid=#{leave_id}&status=0"
      RestClient.post(url, {timeout: 10})
    end

    def approve_created_leave(leave_id)
      url = "#{ZOHO_API_URL}#{APPROVE_LEAVE}?authtoken=#{Rails.application.secrets[:zoho_people_auth]}&pkid=#{leave_id}&status=1"
      RestClient.post(url, {timeout: 10})
    end

    def create_transactions(user_id)
      user = User.find_by(login: user_id)

      unless user.coach?
        #decrease user balance
        Transaction.create!(comment: "Salary for #{@params['date'].to_time.strftime("%d/%m/%y")}", total: "-#{user.daily_rate*@params['percentage'].to_f}", account: user.balance_account, user_id: user.id)
        #increase user payroll
        Transaction.create!(comment: "Salary for #{@params['date'].to_time.strftime("%d/%m/%y")}", total: user.daily_rate*@params['percentage'].to_f, account: user.payroll_account, user_id: user.id)
        #decrease manager balance
        Transaction.create!(comment: "Salary #{user.name} #{@params['date'].to_time.strftime("%d/%m/%y")}", total: "-#{user.daily_rate*@params['percentage'].to_f}", account: user.team.manager.balance_account, user_id: user.id)
      end
    end

    def get_employee_id(user_id)
      url = "#{ZOHO_API_URL}#{GET_EMPOYEES}?authtoken=#{Rails.application.secrets[:zoho_people_auth]}&searchColumn=EMPLOYEEID&searchValue=#{user_id}"
      request = self.parsing_zoho_data(RestClient.get(url))
      request[0]['recordId'].to_i
    end

    def get_leave_type_id(leave_name)
      if leave_name == 'Working'
        leave_type_id = '319617000000127362'
      elsif leave_name == 'Sick [Paid]'
        leave_type_id = '319617000000123013'
      elsif leave_name == 'Day off/Vacation'
        leave_type_id = '319617000000123007'
      else
        @message = 'Invalid leave type'
      end
      leave_type_id
    end

    def parsing_zoho_data(raw_data)
      parsed_data = JSON.parse(raw_data)
      parsed_data[0]['message'] == 'Records not found' ? [] : parsed_data
    end

    def prepare_date(date)
      Date.parse(date)
    end

    # def parse_username(user_id)
    #   zoho_id = ''
    #   url = "#{ZOHO_API_URL}#{GET_EMPOYEES}?authtoken=#{Rails.application.secrets[:zoho_people_auth]}"
    #   request = self.parsing_zoho_data(RestClient.get(url))
    #   request.each do |user|
    #     zoho_id = user['EmployeeID'] if user['recordId'] == user_id
    #   end
    #   zoho_id
    # end
  end
end