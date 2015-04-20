require_relative '../shiftplanning/api'

namespace :shiftplanning do

  task :test => :environment do
    puts Transaction.count
  end

  task :update_transactions => :environment do
    logger = Logger.new("#{Rails.root}/log/transactions.log", 7, 2048000)
        salary_logger = Logger.new("#{Rails.root}/log/salary.log", 7, 2048000)
        debug = true
        salary_logger.info  "Time: #{Time.now} Salary update in progress..."
        users = ShiftplanningApi.instance.timesheets
        if users.empty?
          salary_logger.info  "No users with approved shifts found. Terminating."
          salary_logger.info  " " if debug
          return
        end
        salary_logger.info "Users:"
        users.each {|user| salary_logger.info "#{user['eid']}"}
        users.each do |u|
          next if u['eid'] == 'stmor'|| u['eid'] == '***REMOVED***'
          user = User.find_by_login(u['eid'])
          binding.pry if user.nil?
          next if user.id == 4
          salary_logger.info  "START processing user #{user.name} with #{user.login} login" if debug
          u['shifts'].each do |shift|
            unless Timesheet.where("user_id = ? and in_day = ?", user.id, shift['in_day'].to_i).first
              salary_logger.info  "#{user.name} has new shift record!" if debug
              salary_logger.info  "Processing it..." if debug
              if user.role.name == 'Manager'
                salary_logger.info  "#{user.name} is manager!" if debug
                begin
                  Transaction.create! comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}", #increase user income
                                      total: "#{user.daily_rate.to_s}",
                                      account: user.income_account,
                                      user_id: user.id
                  Transaction.create! comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}", #decrease team income
                                      total: "-#{user.daily_rate.to_s}",
                                      account: user.team.income_account,
                                      user_id: user.id
                rescue => e
                  binding.pry
                  logger.error "#{Time.now} Transactions for #{user.name} was not created!"
                end
              else
                begin
                  Transaction.create! comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}", #decrease user balance
                                      total: "-#{user.daily_rate.to_s}",
                                      account: user.balance_account,
                                      user_id: user.id
                  Transaction.create! comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}", #increase user income
                                      total: "#{user.daily_rate.to_s}",
                                      account: user.income_account,
                                      user_id: user.id
                  Transaction.create! comment: "Salary #{user.name} for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}", #decrease team balance
                                      total: "-#{user.daily_rate.to_s}",
                                      account: user.team.balance_account,
                                      user_id: user.id
                  Transaction.create! comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}", #decrease team income
                                      total: "-#{user.daily_rate.to_s}",
                                      account: user.team.income_account,
                                      user_id: user.id
                rescue => e
                  binding.pry
                  logger.error "#{Time.now} Transactions for #{user.name} was not created!"
                end
              end
              salary_logger.info  "Shift record has been proceed" if debug
            end
            unless Timesheet.find_by_sp_id(shift['id'])
              Timesheet.create! :sp_id => shift['id'],
                                :user_id => user.id,
                                :start_timestamp => shift['start_timestamp'],
                                :end_timestamp => shift['end_timestamp'],
                                :in_day => shift['in_day']
              end
          end
          salary_logger.info  "END processing user #{user.name} with #{user.login} login" if debug
          salary_logger.info  " " if debug
        end
        salary_logger.info  "Salary update complete."
  end
  task :check_transactions  => :environment do
    User.all.each do |user|
      if user.income_account.transactions.where(comment:"Salary for 14/04/15").count >= 2
        puts user.name
        Transaction.create! comment: "This user has 2 salary for 14 of April. Balanse increased.",
                            total: "#{user.daily_rate.to_s}",
                            account: user.balance_account,
                            user_id: user.id
        Transaction.create! comment: "This user has 2 salary for 14 of April. Balanse decreased.",
                            total: "-#{user.daily_rate.to_s}",
                            account: user.income_account,
                            user_id: user.id
        Transaction.create! comment: "User #{user.name} has 2 salary for 14 of April. Balanse increased.",
                            total: "#{user.daily_rate.to_s}",
                            account: user.team.balance_account,
                            user_id: user.id
        Transaction.create! comment: "User #{user.name} has 2 salary for 14 of April. Balanse increased.",
                            total: "#{user.daily_rate.to_s}",
                            account: user.team.income_account,
                            user_id: user.id
      end
    end
  end
end

namespace :temp do
  task :budget  => :environment do
    Task.all.each do |task|
      budget = 0
      task.task_orders.each do |r|
        budget += r.budget
      end
      task.update_attribute(:budget,budget)
    end
  end
end
