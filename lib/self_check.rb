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
    #messages << accepted_and_paid_for_teams
    messages << orders_complete_flag
    messages << task_uniqness
    messages << ticket_paid_status
    # Transaction.where.not(id: @transactions.join(',')).where.not('comment LIKE "%salary%"').each do |transaction|
    #   messages << "Transaction ##{transaction.id}: #{transaction.comment} wrong!"
    # end
    messages.flatten!
  end

  private

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

  def task_uniqness
    tasks = []
    messages = []
    Task.all.each do |task|
      messages << "Task #{task.external_id} has a double" if tasks.include? task.external_id
      tasks << task.external_id
    end
    messages
  end

  def accepted_and_paid_transactions
    messages = []
    Task.where(accepted: true, paid: true).each do |task|
      transactions = []
      next unless task.user.present?
      val = 0
      Transaction.where("comment LIKE '%#{task.external_id}%'").each { |r| val += r.total; @transactions << r.id }
      if (task.budget * 3) != val
        messages << "Wrong payment & balance transactions for issue #{task.external_id}"
      end
    end
    messages
  end

  def task_state
    messages = []
    Team.all.each do |team|
      team.balance_account.transactions.where.not('comment LIKE "Salary%"').each do |t|
        @transactions << t.id
        if team.income_account.transactions.where("comment LIKE '#{t.comment}'").empty?
          messages << "Wrong payment & balance transactions for issue #{t.gsub(/\D/, '')}"
        end
      end
    end
    Task.all.each do |task|
      accepted = Transaction.where("comment LIKE 'Accepted and paid issue #{task.external_id}'")
      reopening = Transaction.where("comment LIKE 'Reopening issue #{task.external_id}'")
      accepted.each { |r| @transactions << r.id }
      reopening.each { |r| @transactions << r.id }
      next if accepted.last.nil?
      if reopening.last.present? && accepted.last.created_at > reopening.last.created_at
        val = 0
        accepted.each { |r| val += r.total }
        reopening.each { |r| val += r.total }
        if (task.budget * 3) != val
          messages << "Issue #{task.external_id} has incorrect number of transactions"
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
    User.all.each do |user|
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
            messages << "Expecting issue ##{id} to be accepted&paid. Team: #{user.team.name}" # неправильное количество транзакций, поменять сообшение
          elsif accepted_count < reopening_count
            messages << "Expecting issue ##{id} NOT to be accepted&paid. Team: #{user.team.name}" # неправильное количество транзакций
          end
        end
      end
    end
    messages
  end

  def salary
    messages = []
    User.all.each do |user|
      user.balance_account.transactions.where('comment LIKE "Salary%"').each do |t|
        @transactions << t.id
        user_income_count = user.income_account.transactions.where("comment LIKE '#{t.comment}' AND total = #{t.total.abs}").count
        team_balance_count = 0
        Team.all.each do |team|
          team_balance_count += team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}' AND total = #{-t.total.abs}").count
        end
        #team_balance_count = user.team.balance_account.transactions.where("comment LIKE '#{t.comment.gsub('for', user.name)}' AND total = #{-t.total.abs}").count
        if user_income_count != 1
          messages << "Wrong salary transaction for #{user.name}'s income account. Details: #{t.comment}"
        end
        if team_balance_count != 1
          messages << "Wrong salary transaction for #{user.name}'s team(#{user.team.name}) balance account. Check: #{t.comment.gsub('for', user.name)}"
        end
      end
    end
    messages
  end

  def accepted_and_paid
    messages = []
    User.all.each do |user|
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
    Task.all.each do |task|
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
    Order.where.not(parent_id: nil).each do |order|
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
    Order.where.not(parent_id: nil).each do |order|
      begin
        unless order.parent.present?
          messages << "SubOrder #{order.id} (#{order.name}) belongs to defunct parent "
        end
      rescue
      end
    end

    # Suborder cannot be parent for another suborders
    Order.where.not(parent_id: nil).each do |order|
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
    Order.all.each do |order|
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
    Order.all.each do |order|
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
    Order.all.each do |order|
      begin
        if order.sub_orders.present?
          val = 0
          order.task_orders.each { |r| val += r.budget}
          order.sub_orders.each { |r| val += r.invoiced_budget }
          calculated_budget = order.allocatable_budget - val
          if calculated_budget < 0
            messages << "Expecting order #{order.id} (#{order.name}) free budget to be greater than zero"
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
    Task.all.each do |task|
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
    Task.all.each do |task|
      begin
        orders = []
        task.task_orders.each { |r| orders << r.order}
        if orders.length > task.task_orders.count
          messages << "Task #{task.external_id} has multiple budgets from one order"
        end
      rescue
      end
    end
    messages
  end
end
