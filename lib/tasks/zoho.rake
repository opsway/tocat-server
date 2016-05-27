require 'csv'
namespace :zoho do
  task :export => :environment do
    files = {
      "zohoreports_accounts.csv" => 'SELECT "id","account_type","created_at","updated_at","accountable_id","accountable_type" UNION SELECT id, account_type, created_at, updated_at, IFNULL(accountable_id,\'\'), accountable_type FROM accounts',
      "zohoreports_transactions.csv" => 'SELECT "id","total","comment","account_id","created_at" UNION SELECT id,total,replace(comment,\'\r\n\',\';\'),account_id,created_at FROM transactions',
      "zohoreports_orders.csv" => ' SELECT "id", "name", "paid", "team_id", "invoice_id", "invoiced_budget", "allocatable_budget", "created_at", "updated_at", "parent_id", "free_budget", "completed", "internal_order", "commission" UNION SELECT id, IFNULL(name,\'\'), paid, IFNULL(team_id,\'\'), IFNULL(invoice_id,\'\'), IFNULL(invoiced_budget,\'\'), IFNULL(allocatable_budget,\'\'), created_at, updated_at, IFNULL(parent_id,\'\'), IFNULL(free_budget,\'\'), completed, internal_order, IFNULL(commission,\'\') FROM orders',
      "zohoreports_teams.csv" => ' SELECT "id","name","created_at","updated_at","default_commission" UNION SELECT id,name,created_at,updated_at, IFNULL(default_commission,\'\') FROM teams',
      "zohoreports_users.csv" => ' SELECT "id","name","login","team_id","daily_rate","created_at","updated_at","role_id","active" UNION SELECT id,name,login,team_id,daily_rate,created_at,updated_at,role_id,active FROM users ',
      "zohoreports_invoices.csv" => ' SELECT "id","external_id","paid","created_at","updated_at" UNION SELECT id,external_id,paid,created_at,updated_at FROM invoices ',
      "zohoreports_tasks.csv" => 'SELECT "id", "external_id","accepted","budget","review_requested","expenses","paid","created_at","updated_at" UNION SELECT id, external_id,accepted,budget,review_requested,expenses,paid,created_at,updated_at FROM tasks',
      "zohoreports_taskorders.csv" => 'SELECT "id","task_id","order_id","budget","created_at","updated_at" UNION SELECT id,task_id,order_id,budget,created_at,updated_at FROM task_orders'
    }
    files.each do |file,sql|
      r = ActiveRecord::Base.connection.execute sql
      CSV.open("/tmp/#{file}", 'wb', force_quotes: true) do |csv|
        r.each do |data|
          csv << data 
        end
      end
    end
  end
end
