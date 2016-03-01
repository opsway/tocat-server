require 'csv'
require 'benchmark'

namespace :budget do
  task :parse => :environment do
    time_elapsed = Benchmark.measure do
      CSV_NAME = 'delta_budget.csv'

      CSV.open("/tmp/#{CSV_NAME}", 'wb') do |csv|
        csv << %w(external_id team_id budget date type)
      end

      database_config = 'config/database.yml'
      database_env = Rails.env

      config = YAML::load_file(database_config)[database_env]
      config['host'] = config['hostname']

      @client = Mysql2::Client.new(config)

      events = @client.query("SELECT *
                          FROM activities a
                          WHERE a.key='task.budget_update' OR a.key='task.accepted_update'")
      missing_tasks = []

      def get_order(task)
        @client.query("SELECT order_id FROM task_orders t WHERE t.task_id='#{task['id']}'").to_a.last
      end

      def get_team(order_id, property)
        team_id = @client.query("SELECT team_id FROM orders o WHERE o.id='#{order_id}'").first
        @client.query("SELECT * FROM teams t WHERE t.id='#{team_id['team_id']}'").first[property] if team_id
      end

      def set_budget(event)
        if event['key'] == 'task.accepted_update'
          budget = parse_budget(previous_budget_update(event))
          if accepted?(event['parameters'])
            budget
          else
            accepted?(previous_accepted_update(event)) && check_doubles(event) ? - budget : 0
          end
        elsif event['key'] == 'task.budget_update'
          current_budget = parse_budget(event)
          prev_budget = parse_budget(previous_budget_update(event))
          if acceptance(event)
            current_budget - prev_budget
          else
            0
          end
        end
      end

      def get_multiplier(order_id, event)
        order = @client.query("SELECT * FROM orders o WHERE o.id='#{order_id}'").first
        if order
          multiplier = order['invoiced_budget'] / order['allocatable_budget']
          multiplier.to_f
        else
          1
        end
      end

      def check_doubles(event)
        events = @client.query("SELECT * FROM activities a WHERE a.trackable_id='#{event['trackable_id']}' AND a.key='task.accepted_update' AND a.created_at = '#{event['created_at']}'").to_a
        events.first == event ? true : false
      end

      def previous_budget_update(event)
        budget_updates = @client.query("SELECT * FROM activities a WHERE a.trackable_id='#{event['trackable_id']}' AND a.key='task.budget_update' AND a.created_at < '#{event['created_at']}'").to_a
        return if budget_updates == []
        budget_updates.last
      end

      def previous_accepted_update(event)
        budget_updates = @client.query("SELECT * FROM activities a WHERE a.trackable_id='#{event['trackable_id']}' AND a.key='task.accepted_update' AND a.created_at < '#{event['created_at']}'").to_a
        return if budget_updates == []
        budget_updates.last['parameters']
      end

      def parse_budget(budget_update)
        return 0 unless budget_update
        new_budget = budget_update['parameters'].split(':new:').last
        new_budget.match('budget:\s+.+').to_s.match('\d+').to_s.to_i
      end

      def acceptance(event)
        accepted_updates = @client.query("SELECT * FROM activities a WHERE a.trackable_id='#{event['trackable_id']}' AND a.key='task.accepted_update' AND a.created_at < '#{event['created_at']}'").to_a
        accepted?(accepted_updates.last['parameters']) if accepted_updates !=[]
      end

      def accepted?(params)
        if params
          if params.match('new:\s*[a-z]+').to_s.split(' ').last == 'true'
            true
          else
            false
          end
        end
      end

      CSV.open("/tmp/#{CSV_NAME}", 'a+') do |csv|
        events.each do |event|
          task = @client.query("SELECT * FROM tasks t WHERE t.id='#{event['trackable_id']}'").first
          if task
            order = get_order(task)
            order_id = order['order_id'] if order
            multiplier = get_multiplier(order_id, event)
            external_id = task['external_id']
            team_id = get_team(order_id, 'id') if order_id
            budget = (set_budget(event) * multiplier).round(2)
            date = event['created_at'].to_date
            type = event['key']
            csv << [external_id, team_id, budget, date, type] unless budget == 0
          else
            missing_tasks << event['trackable_id']
          end
        end
      end
    end
    puts "time spent on building csv #{time_elapsed}"
  end
end
