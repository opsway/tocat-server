# -*- coding: utf-8 -8
require 'singleton'
require_relative 'zoho/api'
require 'ruby-prof'

class SelfCheck
  include Singleton
  def start_with_prof
    RubyProf.start
    prefix_check
    result = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open('fullprof.html','wb') do |f|
      printer.print(f) 
    end
  end

  def start
    status = StatusCheck.create(start_run: Time.now)
    @transactions = []
    @alerts = []
    prefix_check
    manager_status
    paid_status
    orders_relationship
    invoiced
    parents_budget
    free_budget
    budget_teams
    duplicate_budgets
    accepted_and_paid
    salary
    task_state
    accepted_and_paid_transactions
    accepted_and_paid_for_teams
    orders_complete_flag
    task_uniqness
    ticket_paid_status
    transactions
    complete_transactions
    check_invoices
    zero_transactions
    Transaction.includes(account: :accountable).where.not(id: @transactions.flatten.uniq).where.not('comment LIKE "%Paid in cash/bank%"').each do |transaction|
      if /Salary for.*/.match(transaction.comment).present?
        next if transaction.account.accountable.try(:role).try(:name) == 'Manager'
      end
      if transaction.account.accountable_type == 'Team'
        comment = transaction.comment.split
        if comment.length == 4
          user = User.where(name: "#{comment[1]} #{comment[2]}").first
          next if user.present? && (user.try(:role).try(:name) == 'Manager')
        end
      end
      if transaction.comment.match(/^Expense, Issue/)
        task_external_id = transaction.comment.split.last.gsub(/#/,'')
        task = Task.find_by_external_id task_external_id
        next if task.expenses
      end
      @alerts << DbError.store("Unexpected transaction ##{transaction.id}: #{transaction.comment}")
    end
    DbError.where.not(id: @alerts.flatten.uniq).destroy_all
    Rails.cache.write('last_success_self_start', Time.now)
    status.finish_run = Time.now
    status.save
  end

  private
  
  def prefix_check
    Task.where('external_id not regexp ".*_[0-9]+$"').find_each do |task|
        @alerts << DbError.store("Wrong task external_id ##{task.external_id}")
    end
    
    Transaction.where("comment like '%issue%'").where('comment not regexp ".*_[0-9]+.*"').find_each do |t|
        @alerts << DbError.store("Wrong transaction issue_id ##{t.id}")
    end
  end

  def manager_status
    User.joins(:role).where("roles.name='Manager'").find_each do |user|
      user.transactions.where("comment like 'Reopening%'").find_each do |t|
        @alerts << DbError.store("Wrong transaction ##{t.id} for user with Manager role")
      end
      user.transactions.where("comment like 'Accepted and paid%'").find_each do |t|
        @alerts << DbError.store("Wrong transaction ##{t.id} for user with Manager role")
      end
    end
  end

  def check_invoices
    RedmineTocatApi.get_invoices.each do |record|
      record.symbolize_keys!
      invoice = Invoice.where(external_id: record[:invoice_id]).first
      if invoice.present?
        if record[:status] == 'draft'
          @alerts << DbError.store("Invoice #{invoice.external_id}(#{record[:invoice_number]} in zoho) is in DRAFT status.")
          next
        end
        if record[:status] == 'void'
          @alerts << DbError.store("Invoice #{invoice.external_id}(#{record[:invoice_number]} in zoho) is in VOID status.")
          next
        end
        if record[:currency_code] == "USD"
          @alerts << DbError.store("Invoice #{invoice.external_id}(#{record[:invoice_number]} in zoho) has invalid total: It has #{invoice.total}, but it should be #{record[:total]}.") if invoice.total != record[:total]
          record[:status] == 'paid' ?
            status = true :
            status = false
          @alerts << DbError.store("Invoice #{invoice.external_id}(#{record[:invoice_number]} in zoho) has invalid paid status.") if invoice.paid != status
        else
          @alerts << DbError.store("Invoice #{invoice.external_id}(#{record[:invoice_number]} in zoho) has invalid total: It has #{invoice.total}, but it should be #{record[:total] * record[:exchange_rate]}.") if invoice.total != (record[:total] * record[:exchange_rate])
        end
      end
    end
  end

  def transactions
    date_of_start = Date.parse('1/10/2015') # From this date we don't count manager transactions in Team payment and Team balance accounts - issue 34546
    User.find_each do |user|
      user.balance_account.transactions.each do |t|
        if /Salary.*/.match(t.comment).present?
          records = user.income_account.transactions.where("comment LIKE '#{t.comment}'")
          @alerts << DbError.store("Wrong nubmer of salary transactions for #{user.name} payment account. Check: #{t.id}: #{t.comment}") if records.count > 1
          if records.count < 1
            @alerts << DbError.store("Missing salary transaction for #{user.name} payment account. Check: #{t.comment}")
          else
            @alerts << DbError.store("Invalid total for salary transaction for #{user.name} payment account. Check: ##{records.first.id}") if records.first.try(:total).try(:abs) != t.total.abs
          end

          team_balance_records = []
          Team.find_each { |team| team_balance_records << team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_balance_records.flatten!
          @alerts << DbError.store("Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) balance account. Check: #{t.id}: #{t.comment}") if team_balance_records.count > 1
          if team_balance_records.count < 1
            if user.role.name != 'Manager' || Date.strptime(t.comment.split.last,'%d/%m/%y') < date_of_start # issue 34546
              @alerts << DbError.store("Missing salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}")
            end
          else
            @alerts << DbError.store("Invalid total for salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: ##{records.first.id}") if team_balance_records.first.try(:total).try(:abs) != t.total.abs
          end

          team_payment_records = []
          Team.find_each { |team| team_payment_records << team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_payment_records.flatten!
          @alerts << DbError.store("Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) payment account. Check: #{t.id}: #{t.comment}") if team_payment_records.count > 1
          if team_payment_records.count < 1
            if user.role.name != 'Manager' || Date.strptime(t.comment.split.last,'%d/%m/%y') < date_of_start # issue 34546
              @alerts << DbError.store("Missing salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: #{t.comment.gsub('for', user.name)}")
            end
          else
            @alerts << DbError.store("Invalid total for salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: ##{records.first.id}") if team_payment_records.first.try(:total).try(:abs) != t.total.abs
          end
        end
      end
      user.income_account.transactions.each do |t|
        if /Salary.*/.match(t.comment).present?
          records = user.balance_account.transactions.where("comment LIKE '#{t.comment}'")
          @alerts << DbError.store("Wrong nubmer of salary transactions for #{user.name} balance account. Check: #{t.id}: #{t.comment}") if records.count > 1
          if records.count < 1
            if user.role.name != 'Manager' || Date.strptime(t.comment.split.last,'%d/%m/%y') < date_of_start # issue 34546
              @alerts << DbError.store("Missing salary transaction for #{user.name} balance account. Check: #{t.comment}") unless user.role.name == 'Manager'
            end
          else
            @alerts << DbError.store("Invalid total for salary transaction for #{user.name} balance account. Check: ##{records.first.id}") if records.first.try(:total).try(:abs) != t.total.abs
          end

          team_balance_records = []
          Team.find_each { |team| team_balance_records << team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_balance_records.flatten!
          @alerts << DbError.store("Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) balance account. Check: #{t.id}: #{t.comment}") if team_balance_records.count > 1
          if team_balance_records.count < 1
            if user.role.name != 'Manager' || Date.strptime(t.comment.split.last,'%d/%m/%y') < date_of_start # issue 34546
              @alerts << DbError.store("Missing salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}") unless user.role.name == 'Manager'
            end
          else
            @alerts << DbError.store("Invalid total for salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: ##{records.first.id}") if team_balance_records.first.try(:total).try(:abs) != t.total.abs
          end

          team_payment_records = []
          Team.find_each { |team| team_payment_records << team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_payment_records.flatten!
          @alerts << DbError.store("Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) payment account. Check: #{t.id}: #{t.comment}") if team_payment_records.count > 1
          if team_payment_records.count < 1
            if user.role.name != 'Manager' || Date.strptime(t.comment.split.last,'%d/%m/%y') < date_of_start # issue 34546
              @alerts << DbError.store("Missing salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: #{t.comment.gsub('for', user.name)}")
            end
          else
            @alerts << DbError.store("Invalid total for salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: ##{records.first.id}") if team_payment_records.first.try(:total).try(:abs) != t.total.abs
          end
        end
      end
    end
  end

  def orders_complete_flag
    Order.where(completed: true).each do |order|
      valid = true
      order.sub_orders.each do |s_order|
        valid = false unless s_order.completed
        s_order.tasks.each do |task|
          valid = false unless task.accepted && task.paid
        end
      end
      order.tasks.each do |task|
        valid = false unless task.accepted && task.paid
      end
      @alerts << DbError.store("Wrong completed flag for #{order.name}. Check suborders and tasks.") unless valid
    end
  end

  def complete_transactions
    central_office_id = Team.central_office.id
    Order.find_each do |order|
      completed_count = 0
      uncompleted_count = 0
      Transaction.where("comment LIKE ?", "Order ##{order.id} was %").find_each do |t|
        @transactions << t.id
        if /.* was completed/.match(t.comment).present?
          completed_count += 1
        elsif /.* was uncompleted/.match(t.comment).present?
          uncompleted_count += 1
        end
      end
      if completed_count == 0 && order.completed
        @alerts << DbError.store("Order #{order.id} completed, but theres no transaction for it.")
        next
      end
      if uncompleted_count > completed_count
        @alerts << DbError.store("Order #{order.id} contains multiple uncompleted transactions.")
        next
      end
      if order.updated_at > Date.parse('1/10/2015')
        if order.completed
          # 1 + 2 c сentral office + 1 - на сentral_office_income account + 2(возможно) - на team.manager and team.income_account
          correct_count = 1
          if !order.internal_order? && order.team_id != central_office_id
            base_commission = order.commission.presence || 400
            value = value = order.invoiced_budget * base_commission/100.0
            correct_count += 2 if value != 0 
          end
          if order.team_id != central_office_id
            income_balance = order.team.income_account.transactions.where('created_at >= ?', order.updated_at).sum(:total)
            correct_count += 2 if income_balance > 0
          end
          correct_count += 1 unless order.internal_order?
          if correct_count != (completed_count - uncompleted_count).abs 
            @alerts << DbError.store("Order #{order.id} completed transactions wrong, please check it.")
          end
        end
      else
        if (completed_count - uncompleted_count).abs > 1
          @alerts << DbError.store("Order #{order.id} completed transactions wrong, please check it.")
        end
      end
    end
  end

  def task_uniqness #FIXME!!! WTF? 
    tasks = []
    Task.find_each do |task|
      @alerts << DbError.store("Task #{task.external_id} has a double") if tasks.include? task.external_id
      tasks << task.external_id
    end
  end

  def accepted_and_paid_transactions
    Task.includes(:user).where(accepted: true, paid: true).each do |task|
      transactions = []
      next unless task.user.present?
      next if task.accepted && task.user.try(:role).try(:name) == 'Manager'
      val = 0
      Transaction.where("comment LIKE '%issue #{task.external_id}%'").each { |r| val += r.total; @transactions << r.id }
      if (task.budget * 3) != val
        @alerts << DbError.store("Wrong payment & balance transactions for issue #{task.external_id}")
      end
    end
  end

  def task_state
    Team.includes(accounts: :transactions).find_each do |team|
      team.balance_account.transactions.where.not('comment LIKE "Salary%"').where.not('comment LIKE "Setup new team"').each do |t|
        @transactions << t.id
        if team.income_account.transactions.where("comment LIKE '#{t.comment}'").empty?
          @alerts << DbError.store("Wrong payment & balance transactions for issue #{t.comment.gsub(/\D/, '')}")
        end
      end
    end
    Task.includes(:user).find_each do |task|
      accepted = Transaction.where("comment LIKE 'Accepted and paid issue #{task.external_id}'")
      reopening = Transaction.where("comment LIKE 'Reopening issue #{task.external_id}'")
      @transactions << accepted.ids
      @transactions << reopening.ids
      next if accepted.last.nil?
      next if task.accepted && task.user.try(:role).try(:name) == 'Manager'
      if reopening.last.present? && accepted.last.created_at > reopening.last.created_at
        val = 0
        accepted.each { |r| val += r.total }
        reopening.each { |r| val += r.total }
        if (task.budget * 3) != val
          @alerts << DbError.store("Issue #{task.external_id} has incorrect number of transactions")
        end
      elsif reopening.last.nil?
        val = 0
        accepted.each { |r| val += r.total }
        if (task.budget * 3) != val
          @alerts << DbError.store("Issue #{task.external_id} has incorrect number of transactions")
        end
      end
    end
  end

  def accepted_and_paid_for_teams
    User.includes(accounts: :transactions).find_each do |user|
      issues = []
      user.balance_account.transactions.where.not('comment LIKE "Salary%"').each do |t|
        issues << t.comment.gsub(/\D/, '')
        @transactions << t.id
      end
      issues.each do |id|
        accepted_count = 0
        reopening_count = 0
        user.team.balance_account.transactions.where("comment LIKE '%#{id}%'").each do |t_|
          if /Accepted and paid issue.*/.match(t_.comment).present?
            accepted_count += 1
          elsif /Reopening issue.*/.match(t_.comment).present?
            reopening_count += 1
          end
        end
        next if reopening_count == 0
        if (accepted_count - reopening_count).abs > 1
          if accepted_count > reopening_count
            @alerts << DbError.store("Wrong team transaction count: Expecting issue ##{id} to be accepted&paid. Team: #{user.team.name}")
          elsif accepted_count < reopening_count
            @alerts << DbError.store("Wrong team transaction count: Expecting issue ##{id} NOT to be accepted&paid. Team: #{user.team.name}")
          end
        end
      end
    end
  end

  def salary
   #team_transactions = {}

   #Team.includes(accounts: :transactions).find_each do |team|
   #  team_transactions[team.id] = {}
   #  team_transactions[team.id][:balance] = team.balance_account.trransactions
   #  team_transactions[team.id][:income] = team.income_account.transactions
   #end
    date_of_start = Date.parse('1/10/2015') # From this date we don't count manager transactions in Team payment and Team balance accounts - issue 34546
    User.find_each do |user|
      user.balance_account.transactions.where('comment LIKE "Salary %"').each do |t|
        @transactions << t.id
        user_income_count = user.income_account.transactions.where("comment LIKE '#{t.comment}' AND total = #{t.total.abs}").count
        @transactions << user.income_account.transactions.where("comment LIKE '#{t.comment}' AND total = #{t.total.abs}").ids
        team_balance_count = 0
        team_payment_count = 0
        Team.find_each do |team|
          team_balance_count += team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").count
          team_payment_count += team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").count
          @transactions << team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").ids
          @transactions << team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").ids
        end
        if user_income_count != 1
          @alerts << DbError.store("Wrong salary transaction for #{user.name}'s income account. Details: #{t.comment}")
        end
        if user.role.name != 'Manager' || Date.strptime(t.comment.split.last,'%d/%m/%y') < date_of_start # issue 34546
          if team_balance_count != 1
            @alerts << DbError.store("Wrong salary transaction for #{user.name}'s team(#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}")
          end
          if team_payment_count != 1
            @alerts << DbError.store("Wrong salary transaction for #{user.name}'s team(#{user.team.name}) income account. Check: #{t.comment.gsub('for', user.name)}")
          end
        else
          if team_balance_count != 0
            @alerts << DbError.store("Wrong salary transaction for #{user.name}'s team(#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}")
          end
          if team_payment_count != 0
            @alerts << DbError.store("Wrong salary transaction for #{user.name}'s team(#{user.team.name}) income account. Check: #{t.comment.gsub('for', user.name)}")
          end
        end
      end
    end
  end

  def accepted_and_paid
    User.includes(accounts: :transactions).find_each do |user|
      issues = []
      user.balance_account.transactions.where.not('comment LIKE "Salary%"').each do |t|
        issues << t.comment.gsub(/\D/, '')
        @transactions << t.id
      end
      issues.each do |id|
        accepted_count = 0
        reopening_count = 0
        user.balance_account.transactions.where("comment LIKE '%#{id}%'").each do |t_| 
          @transactions << t_.id
          if /Accepted and paid issue.*/.match(t_.comment).present?
            accepted_count += 1
          elsif /Reopening issue.*/.match(t_.comment).present?
            reopening_count += 1
          end
        end
        next if reopening_count == 0
        if (accepted_count - reopening_count).abs > 1
          if accepted_count > reopening_count
            @alerts << DbError.store("Wrong transaction count: Expecting issue ##{id} to be accepted&paid.")
          elsif accepted_count < reopening_count
            @alerts << DbError.store("Wrong transaction count: Expecting issue ##{id} NOT to be accepted&paid.")
          end
        end
      end
    end
  end

  def ticket_paid_status
    Task.includes(:orders).find_each do |task|
      next if task.orders.empty?
      statuses = []
      task.orders.each { |o| statuses << o.paid }
      statuses.uniq!
      if task.paid == false && statuses.include?(false)
        next
      end
      if statuses.length > 1
        @alerts << DbError.store("Task ##{task.external_id} has wrong paid status.")
      elsif statuses.first != task.paid
        @alerts << DbError.store("Task ##{task.external_id} has wrong paid status.")
      end
    end
  end

  def paid_status
    # This method should get paid status for suborder and compare it with parent's paid status.
    Order.includes(:parent).where.not(parent_id: nil).each do |order|
      begin
        if order.parent.paid !=  order.paid
          @alerts << DbError.store("Expecting order #{order.id} (#{order.name}) to be #{order.parent.paid ? 'paid' : 'unpaid'}")
        end
      rescue
      end
    end
  end

  def orders_relationship
    # This method should check relationshipt between orders.
    # Suborder should belongs to parent
    Order.includes(:parent).where.not(parent_id: nil).each do |order|
      begin
        unless order.parent.present?
          @alerts << DbError.store("SubOrder #{order.id} (#{order.name}) belongs to defunct parent ")
        end
      rescue
        @alerts << DbError.store("SubOrder #{order.id} (#{order.name}) belongs to defunct parent ")
      end
    end

    # Suborder cannot be parent for another suborders
    Order.includes(:parent).where.not(parent_id: nil).each do |order|
      begin
        unless order.sub_orders.empty?
          @alerts << DbError.store("SubOrder #{order.id} (#{order.name}) has another suborders")
        end
      rescue
      end
    end
  end

  def invoiced
    # This method should check thats only orders (NOT suborders) has relationship with invoices.
    Order.includes(:invoice).find_each do |order|
      begin
        if order.invoice.present? && order.parent_id.present?
          @alerts << DbError.store("SubOrder #{order.id} (#{order.name}) has relationship with invoice")
        end
      rescue
      end
    end
  end

  def parents_budget
    # This method should check free budget for each parent order.
    Order.includes(:task_orders, sub_orders: :task_orders).find_each do |order|
      begin
        if order.sub_orders.present?
          val = 0
          order.task_orders.each { |r| val += r.budget}
          order.sub_orders.each { |r| val += r.invoiced_budget }
          calculated_budget = order.allocatable_budget - val
          if order.free_budget != calculated_budget
            @alerts << DbError.store("Expecting order #{order.id} (#{order.name}) free budget to be #{calculated_budget}, but it #{order.free_budget}")
          end
        end
      rescue
      end
    end
  end

  def free_budget
    # This method should check free budget for each order and this value should be >= 0.
    Order.includes(:sub_orders, :task_orders).find_each do |order|
      begin
        if order.sub_orders.present?
          val = 0
          order.task_orders.each { |r| val += r.budget}
          order.sub_orders.each { |r| val += r.invoiced_budget }
          calculated_budget = order.allocatable_budget - val
          if calculated_budget < 0
            @alerts << DbError.store("Expecting order #{order.id} (#{order.name}) free budget to be greater than zero")
          end
          if val =! (order.free_budget + order.allocatable_budget)
            @alerts << DbError.store("Order #{order.id} (#{order.name}) has invalid free budget!")
          end
        end
      rescue
      end
    end
  end

  def budget_teams
    # This method should check order team.
    Task.includes(orders: :team).find_each do |task|
      begin
        teams = []
        task.orders.each { |r| teams << r.team}
        if teams.uniq.length > 1
          @alerts << DbError.store("Expecting task #{task.external_id} budgets to be from same team")
        end
      rescue
      end
    end
  end

  def zero_transactions
    Transaction.where(total: 0).where("comment like '%issue%'").find_each do |transaction|
      issue = transaction.comment.gsub(/\D/, '')
      @alerts << DbError.store("Transaction id=#{transaction.id} for issue #{issue} has 0 total")
    end
  end

  def duplicate_budgets
    Task.includes(:task_orders, :orders).find_each do |task|
      if task.orders.length > task.task_orders.length
        @alerts << DbError.store("Task #{task.external_id} has multiple budgets from one order")
      end
    end
  end
end
