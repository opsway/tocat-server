namespace :test do
  task :internal => :environment do
    files = Dir.glob('spec/*_spec.js')
    messages = []
    files.each do |file|
      begin
        Rake::Task["sql_data:load"].execute
        sh("jasmine-node #{file}")
      rescue => e
        messages << file
      end
    end
    if messages.any?
      puts "Files with errors:"
      messages.each { |m| puts m }
    end
  end
end
