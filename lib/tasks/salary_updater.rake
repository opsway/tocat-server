require_relative '../shiftplanning/api'

namespace :shiftplanning do

  task :test => :environment do
    puts Transaction.count
  end

  task :update_transactions => :environment do
    #check lockfile 
    lock_file = "/tmp/salary_update_lock"
    if File.exist? lock_file
      pid = File.read lock_file

      # check if process really work (check pid from lockfile)
      process_present =
        begin 
          Process.getpgid pid.to_i
        rescue 
          false
        end
      if process_present
        p 'Lock file present, please wait'
        exit 
      end
    end

    #write pid to lock file
    File.open(lock_file,'w') do |f|
      f.write(Process.pid)
    end

    #count errors 
    errors = 0

    time = Time.now.gmtime.strftime("%d/%m/%Y - %H:%M GMT+0")
    dbid = DbError.where("alert like 'There may be salary processing errors. Last successful run%'").first.try(:id)
    dbid = DbError.store 38, "There may be salary processing errors. Last successful run - #{time}" unless dbid

    logger = Logger.new("#{Rails.root}/log/transactions.log", 7, 2048000)
    salary_logger = Logger.new("#{Rails.root}/log/salary.log", 7, 2048000)
    debug = true
    salary_logger.info "Time: #{Time.now} Salary update in progress..."
    users = ShiftplanningApi.instance.timesheets
    if users.empty?
      salary_logger.info "No users with approved shifts found. Terminating."
      salary_logger.info " " if debug

      #clear errors if nothing to do
      if errors == 0
        Rails.cache.write('update_transactions', Time.now.gmtime) # TODO - check rails cache
        DbError.delete dbid # Remove error if error count == 0 (and if we reached this line)
      end
      exit
    end


    salary_logger.info "Users:"
    users.each { |user| salary_logger.info "#{user['eid']}" }
    users.each do |u|
      next if u['eid'] == 'semor'|| u['eid'] == 'ansam'
      user = User.find_by(login: u['eid'])
      if user.nil?
        salary_logger.error("User with login: #{u['eid']} doesn't exist.")
        binding.pry
      end
      salary_logger.info "START processing user #{user.name} with #{user.login} login" if debug
      u['shifts'].each do |shift|
        unless Timesheet.where("user_id = ? and in_day = ?", user.id, shift['in_day'].to_i).first
          salary_logger.info "#{user.name} has new shift record!" if debug
          salary_logger.info "Processing it..." if debug
          begin
            unless user.real_money?
              #decrease user balance
              Transaction.create!(comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}",
                                  total: "-#{user.daily_rate}",
                                  account: user.balance_account,
                                  user_id: user.id)
              #increase user income
              Transaction.create!(comment: "Salary for #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}",
                                  total: "#{user.daily_rate}",
                                  account: user.income_account,
                                  user_id: user.id)

              unless user.role.try(:name) == 'Manager'
                #decrease team balance
                Transaction.create!(comment: "Salary #{user.name} #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}",
                                    total: "-#{user.daily_rate}",
                                    account: user.team.balance_account,
                                    user_id: user.id)
                #decrease team income
                Transaction.create!(comment: "Salary #{user.name} #{shift['start_timestamp'].to_time.strftime("%d/%m/%y")}",
                                    total: "-#{user.daily_rate}",
                                    account: user.team.income_account,
                                    user_id: user.id)
              end
            end
          rescue => e
            binding.pry
            errors += 1
            logger.error "#{Time.now} Transactions for #{user.name} was not created! - #{e.message}"
          end
        end
        salary_logger.info "Shift record has been proceed" if debug
        unless Timesheet.find_by_sp_id(shift['id'])
          Timesheet.create!(:sp_id => shift['id'],
                            :user_id => user.id,
                            :start_timestamp => shift['start_timestamp'],
                            :end_timestamp => shift['end_timestamp'],
                            :in_day => shift['in_day'])
        end
      end
      salary_logger.info "END processing user #{user.name} with #{user.login} login" if debug
    end
    salary_logger.info " " if debug
    salary_logger.info "Salary update complete."
    if errors == 0
      DbError.delete dbid # Remove error if error count == 0 (and if we reached this line)
    end
    File.unlink lock_file # remove lock file after finish
  end

  task :check_transactions  => :environment do
    User.all.each do |user|
      if user.income_account.transactions.where(comment:"Salary for 14/04/15").count >= 2
        puts user.name
        user.income_account.transactions.where(comment:"Salary for 14/04/15").first.destroy
        user.balance_account.transactions.where(comment:"Salary for 14/04/15").first.destroy
        user.team.balance_account.transactions.where(comment:"Salary #{user.name} 14/04/15")
        # Transaction.create! comment: "This user has 2 salary for 14 of April. Balanse increased.",
        #                     total: "#{user.daily_rate.to_s}",
        #                     account: user.balance_account,
        #                     user_id: user.id
        # Transaction.create! comment: "This user has 2 salary for 14 of April. Balanse decreased.",
        #                     total: "-#{user.daily_rate.to_s}",
        #                     account: user.income_account,
        #                     user_id: user.id
        # Transaction.create! comment: "User #{user.name} has 2 salary for 14 of April. Balanse increased.",
        #                     total: "#{user.daily_rate.to_s}",
        #                     account: user.team.balance_account,
        #                     user_id: user.id
        # Transaction.create! comment: "User #{user.name} has 2 salary for 14 of April. Balanse increased.",
        #                     total: "#{user.daily_rate.to_s}",
        #                     account: user.team.income_account,
        #                     user_id: user.id
      end
    end
  end
end

namespace :transactions do
  task :fix_comment  => :environment do
    Transaction.where('comment LIKE "Salary % for%"').each do |t|
      t.update_attribute(:comment, t.comment.gsub(' for', ''))
      puts t.id
    end
  end

  task :fix_comment_2  => :environment do
    transactions = []
    Transaction.where('comment LIKE "Salary for%"').each {|t| transactions << t if t.account.accountable_type == 'Team'}
    transactions.each do |tr|
      if User.where(daily_rate: tr.total.abs).count == 1
        tr.update_attribute(:comment, tr.comment.gsub('for', User.where(daily_rate: tr.total.abs).first.name))
      else
        if tr.user_id != 0 && tr.user.present?
          tr.update_attribute(:comment, tr.comment.gsub('for', tr.user.name))
        else
          puts tr.id
        end
      end
    end
  end
end
