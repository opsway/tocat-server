namespace :sql_data do
  desc "Load data from sql file."
  task :load do
    unless Rails.env.production?
      connection = ActiveRecord::Base.connection
      connection.tables.each do |table|
        connection.execute("TRUNCATE #{table}") unless table == "schema_migrations"
      end

      sql = File.read('db/import.sql')
      statements = sql.split(/;$/)
      statements.pop

      ActiveRecord::Base.transaction do
        statements.each do |statement|
          connection.execute(statement)
        end
      end
    end
  end
end
