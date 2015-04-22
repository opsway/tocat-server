require 'singleton'

class SelfCheck
  include Singleton

  def start
    messages = []
    messages << paid_status
    messages << orders_relationship
    #messages << invoiced
    #messages << parents_budget
    #messages << free_budget
    messages << budget_teams
    messages << duplicate_budgets
    messages.flatten!
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
      unless order.parent.present?
        messages << "SubOrder #{order.id} (#{order.name}) belongs to defunct parent "
      end
    end

    # Suborder cannot be parent for another suborders
    Order.where.not(parent_id: nil).each do |order|
      unless order.sub_orders.empty?
        messages << "SubOrder #{order.id} (#{order.name}) has another suborders"
      end
    end
    messages
  end

  def invoiced
    # This method should check thats only orders (NOT suborders) has relationship with invoices.
    messages = []
    Order.all.each do |order|
      if order.invoice.present? && order.parent_id.present?
        messages << "SubOrder #{order.id} (#{order.name}) has relationship with invoice"
      end
    end
    messages
  end

  def parents_budget
    # This method should check free budget for each parent order.
    messages = []
    Order.all.each do |order|
      if order.sub_orders.present?
        val = 0
        order.task_orders.each { |r| val += r.budget}
        order.sub_orders.each { |r| val += r.invoiced_budget }
        calculated_budget = order.allocatable_budget - val
        if order.free_budget != calculated_budget
          messages << "Expecting order #{order.id} (#{order.name}) free budget to be #{calculated_budget}, but it #{order.free_budget}"
        end
      end
    end
    messages
  end

  def free_budget
    # This method should check free budget for each order and this value should be >= 0.
    messages = []
    Order.all.each do |order|
      if order.sub_orders.present?
        val = 0
        order.task_orders.each { |r| val += r.budget}
        order.sub_orders.each { |r| val += r.invoiced_budget }
        calculated_budget = order.allocatable_budget - val
        if calculated_budget < 0
          messages << "Expecting order #{order.id} (#{order.name}) free budget to be greater than zero"
        end
      end
    end
    messages
  end

  def budget_teams
    # This method should check order team.
    messages = []
    Task.all.each do |task|
      teams = []
      if task.user.present?
        teams << task.user.team
      end
      task.orders.each { |r| teams << r.team}
      if teams.uniq.length > 1
        messages << "Expecting task #{task.external_id} budgets to be from same team"
      end
    end
    messages
  end

  def duplicate_budgets
    messages = []
    Task.all.each do |task|
      orders = []
      task.task_orders.each { |r| orders << r.order}
      if orders.length > task.task_orders.count
        messages << "Task #{task.external_id} has multiple budgets from one order"
      end
    end
    messages
  end
end
