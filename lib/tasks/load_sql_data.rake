namespace :sql_data do
  desc "Load data from sql file."
  task load: :environment do
    fail 'SQL file not found' unless File.exist?('db/import.sql')
    #unless Rails.env.production?
      connection = ActiveRecord::Base.connection
      sql = File.read('db/import.sql')
      statements = sql.split(/;$/)
      statements.pop

      ActiveRecord::Base.transaction do
        statements.each do |statement|
          connection.execute(statement)
        end
      end
    #end
  end

  desc "Load data from sql file2."
  task load2: :environment do
    fail 'SQL file not found' unless File.exist?('db/import_with_status_errors.sql')
    #unless Rails.env.production?
      connection = ActiveRecord::Base.connection
      sql = File.read('db/import_with_status_errors.sql')
      statements = sql.split(/;$/)
      statements.pop

      ActiveRecord::Base.transaction do
        statements.each do |statement|
          connection.execute(statement)
        end
      end
    #end
  end
end
