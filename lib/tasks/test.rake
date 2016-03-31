require 'csv'
namespace :test do
  task :csv => :environment do
    CSV.open('issues_with_orders.csv','wb') do |csv|
      CSV.foreach(Rails.root.join('issues.csv')) do |line|
        id = line[0]
        subject = line[1]
        created_on = line[2]
        closed_on = line[3]
        budget = line[4]

        task = Task.find_by_external_id(id.to_s)
        unless task
          csv << [id,subject,created_on, closed_on, 'No task/order', budget]
          next unless task
        end
        if (orders = task.orders) && task.orders.any?
            csv << [id,subject,created_on, closed_on, orders.first.name, task.budget]
        else
          csv << [id,subject,created_on, closed_on, 'No order', budget]
        end
      end
    end
  end
  task :internal => :environment do
    Rake::Task["test:coffee"].invoke
    Rake::Task["test:coffee_new_sql"].invoke
    files = Dir.glob('spec/*_spec.js')
    messages = []
    files.each do |file|
      begin
        Rake::Task["sql_data:load"].execute
        sh("jasmine-node --junitreport #{file}")
      rescue => e
        messages << file
      end
    end
    if messages.any?
      puts "Files with errors:"
      messages.each { |m| puts m }
    end
  end

  task :coffee => :environment do
    files = Dir.glob('spec/*_spec.coffee')
    messages = []
    files.each do |file|
      next if file.match(/new_sql/)
      begin
        Rake::Task["sql_data:load"].execute
        sh("jasmine-node --coffee --junitreport #{file}")
      rescue => e
        messages << file
      end
    end
    if messages.any?
      puts "Files with errors:"
      messages.each { |m| puts m }
    end
  end

  task :coffee_new_sql => :environment do
    files = Dir.glob('spec/*new_sql*_spec.coffee')
    messages = []
    files.each do |file|
      begin
        Rake::Task["sql_data:load2"].execute
        sh("jasmine-node --coffee --junitreport #{file}")
      rescue => e
        messages << file
      end
    end
    if messages.any?
      puts "Files with errors:"
      messages.each { |m| puts m }
    end
  end
  task :cf => :environment do
    Rake::Task["sql_data:load"].execute
    sh("jasmine-node --coffee --verbose --junitreport spec/complete_order_commission_spec.coffee")
  end
end
