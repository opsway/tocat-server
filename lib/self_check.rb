require 'singleton'

class SelfCheck
  include Singleton

  def start
    @transactions = []
    messages = []
    messages << paid_status
    messages << orders_relationship
    messages << invoiced
    messages << parents_budget
    messages << free_budget
    messages << budget_teams
    messages << duplicate_budgets
    messages << accepted_and_paid
    messages << salary
    messages << task_state
    messages << accepted_and_paid_transactions
    messages << accepted_and_paid_for_teams
    messages << orders_complete_flag
    messages << task_uniqness
    messages << ticket_paid_status
    messages << transactions
    messages << complete_transactions
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
      messages << "Unexpected transaction ##{transaction.id}: #{transaction.comment}"
    end
    messages.flatten!
  end

  private

  def transactions
    messages = []
    User.find_each do |user|
      user.balance_account.transactions.each do |t|
        if /Salary.*/.match(t.comment).present?
          records = user.income_account.transactions.where("comment LIKE '#{t.comment}'")
          messages << "Wrong nubmer of salary transactions for #{user.name} payment account. Check: #{t.id}: #{t.comment}" if records.count > 1
          if records.count < 1
            messages << "Missing salary transaction for #{user.name} payment account. Check: #{t.comment}"
          else
            messages << "Invalid total for salary transaction for #{user.name} payment account. Check: ##{records.first.id}" if records.first.try(:total).try(:abs) != t.total.abs
          end

          team_balance_records = []
          Team.find_each { |team| team_balance_records << team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_balance_records.flatten!
          messages << "Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) balance account. Check: #{t.id}: #{t.comment}" if team_balance_records.count > 1
          if team_balance_records.count < 1
            messages << "Missing salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}"
          else
            messages << "Invalid total for salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: ##{records.first.id}" if team_balance_records.first.try(:total).try(:abs) != t.total.abs
          end

          team_payment_records = []
          Team.find_each { |team| team_payment_records << team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_payment_records.flatten!
          messages << "Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) payment account. Check: #{t.id}: #{t.comment}" if team_payment_records.count > 1
          if team_payment_records.count < 1
            messages << "Missing salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: #{t.comment.gsub('for', user.name)}"
          else
            messages << "Invalid total for salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: ##{records.first.id}" if team_payment_records.first.try(:total).try(:abs) != t.total.abs
          end
        end
      end
      user.income_account.transactions.each do |t|
        if /Salary.*/.match(t.comment).present?
          records = user.balance_account.transactions.where("comment LIKE '#{t.comment}'")
          messages << "Wrong nubmer of salary transactions for #{user.name} balance account. Check: #{t.id}: #{t.comment}" if records.count > 1
          if records.count < 1
            messages << "Missing salary transaction for #{user.name} balance account. Check: #{t.comment}" unless user.role.name == 'Manager'
          else
            messages << "Invalid total for salary transaction for #{user.name} balance account. Check: ##{records.first.id}" if records.first.try(:total).try(:abs) != t.total.abs
          end

          team_balance_records = []
          Team.find_each { |team| team_balance_records << team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_balance_records.flatten!
          messages << "Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) balance account. Check: #{t.id}: #{t.comment}" if team_balance_records.count > 1
          if team_balance_records.count < 1
            messages << "Missing salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}" unless user.role.name == 'Manager'
          else
            messages << "Invalid total for salary transaction for #{user.name} team (#{user.team.name}) balance account. Check: ##{records.first.id}" if team_balance_records.first.try(:total).try(:abs) != t.total.abs
          end

          team_payment_records = []
          Team.find_each { |team| team_payment_records << team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'")}
          team_payment_records.flatten!
          messages << "Wrong nubmer of salary transactions for #{user.name} team (#{user.team.name}) payment account. Check: #{t.id}: #{t.comment}" if team_payment_records.count > 1
          if team_payment_records.count < 1
            messages << "Missing salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: #{t.comment.gsub('for', user.name)}"
          else
            messages << "Invalid total for salary transaction for #{user.name} team (#{user.team.name}) payment account. Check: ##{records.first.id}" if team_payment_records.first.try(:total).try(:abs) != t.total.abs
          end
        end
      end
    end
    messages
  end

  def orders_complete_flag
    messages = []
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
      messages << "Wrong completed flag for #{order.name}. Check suborders and tasks." unless valid
    end
    messages
  end

  def complete_transactions
    messages = []
    Order.find_each do |order|
      completed_count = 0
      uncompleted_count = 0
      Transaction.where("comment LIKE ?", "Order ##{order.id} was %").find_each do |t|
        @transactions << t.id
        if /.* was completed/.match(t.comment).present?
          completed_count += 1
          if t.total != (order.invoiced_budget - order.sub_orders.sum(:invoiced_budget) - order.task_orders.sum(:budget))
            messages << "Wrong complete transaction total for ##{order.id} order"
          end
        elsif /.* was uncompleted/.match(t.comment).present?
          uncompleted_count += 1
        end
      end
      if completed_count == 0 && order.completed
        messages << "Order #{order.id} completed, but theres no transaction for it."
        next
      end
      if uncompleted_count > completed_count
        messages << "Order #{order.id} contains multiple uncompleted transactions."
        next
      end
      if (completed_count - uncompleted_count).abs > 1
        messages << "Order #{order.id} completed transactions wrong, please check it."
      end
    end
    messages
  end

  def task_uniqness
    tasks = []
    messages = []
    Task.find_each do |task|
      messages << "Task #{task.external_id} has a double" if tasks.include? task.external_id
      tasks << task.external_id
    end
    messages
  end

  def accepted_and_paid_transactions
    messages = []
    Task.includes(:user).where(accepted: true, paid: true).each do |task|
      transactions = []
      next unless task.user.present?
      next if task.accepted && task.user.try(:role).try(:name) == 'Manager'
      val = 0
      Transaction.where("comment LIKE '%issue #{task.external_id}%'").each { |r| val += r.total; @transactions << r.id }
      if (task.budget * 3) != val
        messages << "Wrong payment & balance transactions for issue #{task.external_id}"
      end
    end
    messages
  end

  def task_state
    messages = []
    Team.includes(accounts: :transactions).find_each do |team|
      team.balance_account.transactions.where.not('comment LIKE "Salary%"').each do |t|
        @transactions << t.id
        if team.income_account.transactions.where("comment LIKE '#{t.comment}'").empty?
          messages << "Wrong payment & balance transactions for issue #{t.gsub(/\D/, '')}"
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
          messages << "Issue #{task.external_id}  number of transactions"
        end
      elsif reopening.last.nil?
        val = 0
        accepted.each { |r| val += r.total }
        if (task.budget * 3) != val
          messages << "Issue #{task.external_id} has incorrect number of transactions"
        end
      end
    end
    messages
  end

  def accepted_and_paid_for_teams
    messages = []
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
            messages << "Wrong team transaction count: Expecting issue ##{id} to be accepted&paid. Team: #{user.team.name}" # неправильное количество транзакций, поменять сообшение
          elsif accepted_count < reopening_count
            messages << "Wrong team transaction count: Expecting issue ##{id} NOT to be accepted&paid. Team: #{user.team.name}" # неправильное количество транзакций
          end
        end
      end
    end
    messages
  end

  def salary
    messages = []
    User.includes(accounts: :transactions).find_each do |user|
      user.balance_account.transactions.where('comment LIKE "Salary %"').each do |t|
        @transactions << t.id
        user_income_count = user.income_account.transactions.where("comment LIKE '#{t.comment}' AND total = #{t.total.abs}").count
        @transactions << user.income_account.transactions.where("comment LIKE '#{t.comment}' AND total = #{t.total.abs}").ids
        team_balance_count = 0
        team_payment_count = 0
        Team.includes(accounts: :transactions).find_each do |team|
          team_balance_count += team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").count
          team_payment_count += team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").count
          @transactions << team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").ids
          @transactions << team.income_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}'").ids
        end
        if user_income_count != 1
          messages << "Wrong salary transaction for #{user.name}'s income account. Details: #{t.comment}"
        end
        if team_balance_count != 1
          messages << "Wrong salary transaction for #{user.name}'s team(#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}"
        end
        if team_payment_count != 1
          messages << "Wrong salary transaction for #{user.name}'s team(#{user.team.name}) income account. Check: #{t.comment.gsub('for', user.name)}"
        end
      end
    end
    messages
  end

  def accepted_and_paid
    messages = []
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
            messages << "Wrong transaction count: Expecting issue ##{id} to be accepted&paid."
          elsif accepted_count < reopening_count
            messages << "Wrong transaction count: Expecting issue ##{id} NOT to be accepted&paid."
          end
        end
      end
    end
    messages
  end

  def ticket_paid_status
    messages = []
    Task.includes(:orders).find_each do |task|
      next if task.orders.empty?
      statuses = []
      task.orders.each { |o| statuses << o.paid }
      statuses.uniq!
      if task.paid == false && statuses.include?(false)
        next
      end
      if statuses.length > 1
        messages << "Task ##{task.external_id} has wrong paid status."
      elsif statuses.first != task.paid
        messages << "Task ##{task.external_id} has wrong paid status."
      end
    end
    messages
  end

  def paid_status
    # This method should get paid status for suborder and compare it with parent's paid status.
    messages = []
    Order.includes(:parent).where.not(parent_id: nil).each do |order|
      begin
        if order.parent.paid !=  order.paid
          messages << "Expecting order #{order.id} (#{order.name}) to be #{order.parent.paid ? 'paid' : 'unpaid'}"
        end
      rescue
      end
    end
    messages
  end

  def orders_relationship
    # This method should check relationshipt between orders.
    messages = []
    # Suborder should belongs to parent
    Order.includes(:parent).where.not(parent_id: nil).each do |order|
      begin
        unless order.parent.present?
          messages << "SubOrder #{order.id} (#{order.name}) belongs to defunct parent "
        end
      rescue
        messages << "SubOrder #{order.id} (#{order.name}) belongs to defunct parent "
      end
    end

    # Suborder cannot be parent for another suborders
    Order.includes(:parent).where.not(parent_id: nil).each do |order|
      begin
        unless order.sub_orders.empty?
          messages << "SubOrder #{order.id} (#{order.name}) has another suborders"
        end
      rescue
      end
    end
    messages
  end

  def invoiced
    # This method should check thats only orders (NOT suborders) has relationship with invoices.
    messages = []
    Order.includes(:invoice).find_each do |order|
      begin
        if order.invoice.present? && order.parent_id.present?
          messages << "SubOrder #{order.id} (#{order.name}) has relationship with invoice"
        end
      rescue
      end
    end
    messages
  end

  def parents_budget
    # This method should check free budget for each parent order.
    messages = []
    Order.includes(:task_orders, sub_orders: :task_orders).find_each do |order|
      begin
        if order.sub_orders.present?
          val = 0
          order.task_orders.each { |r| val += r.budget}
          order.sub_orders.each { |r| val += r.invoiced_budget }
          calculated_budget = order.allocatable_budget - val
          if order.free_budget != calculated_budget
            messages << "Expecting order #{order.id} (#{order.name}) free budget to be #{calculated_budget}, but it #{order.free_budget}"
          end
        end
      rescue
      end
    end
    messages
  end

  def free_budget
    # This method should check free budget for each order and this value should be >= 0.
    messages = []
    Order.includes(:sub_orders, :task_orders).find_each do |order|
      begin
        if order.sub_orders.present?
          val = 0
          order.task_orders.each { |r| val += r.budget}
          order.sub_orders.each { |r| val += r.invoiced_budget }
          calculated_budget = order.allocatable_budget - val
          if calculated_budget < 0
            messages << "Expecting order #{order.id} (#{order.name}) free budget to be greater than zero"
          end
          #binding.pry if order.id == 43
          if val =! (order.free_budget + order.allocatable_budget)
            messages << "Order #{order.id} (#{order.name}) has invalid free budget!"
          end
        end
      rescue
      end
    end
    messages
  end

  def budget_teams
    # This method should check order team.
    messages = []
    Task.includes(orders: :team).find_each do |task|
      begin
        teams = []
        task.orders.each { |r| teams << r.team}
        if teams.uniq.length > 1
          messages << "Expecting task #{task.external_id} budgets to be from same team"
        end
      rescue
      end
    end
    messages
  end

  def duplicate_budgets
    messages = []
    Task.includes(:task_orders, :orders).find_each do |task|
      if task.orders.length > task.task_orders.length
        messages << "Task #{task.external_id} has multiple budgets from one order"
      end
    end
    messages
  end
end
