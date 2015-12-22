namespace :conv do
  task :convert => :environment do
    Task.find_each do |task|
      unless task.external_id.match(/[a-zA-Z]_/)
        task.external_id = 'opsway_' + task.external_id
        task.save
      end
    end

    Transaction.where("comment like '%issue%' and comment not like '%opsway_[0-9]%'").find_each do |t|
      t.comment = t.comment.gsub(/([0-9]+)/, 'opsway_\1')
      t.save
    end
  end
end
