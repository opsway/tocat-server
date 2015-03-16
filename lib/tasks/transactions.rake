require_relative '../zoho/api'

namespace :zoho do
  task :transactions => :environment do
    RedmineTocatApi.get_transactions.each do |record|
      begin
        if record['Account'].split().count == 3
          if record['Account'].split().first == 'Central'
            owner = Team.find_by(name:"#{record['Account'].split().first} #{record['Account'].split().second}")
          else
            owner = User.find_by(name:"#{record['Account'].split().first} #{record['Account'].split().second}")
          end
        else
          owner = Team.find_by(name:record['Account'].split.first)
        end
        unless owner.present?
          puts "Cound't find owner for #{record}"
          next
        end
        if record['Account'].split().last == 'Balance'
          account = owner.balance_account
        else
          account = owner.income_account
        end
        unless account.present?
          puts "Cound't find account for #{record}, with #{owner.name} as owner"
          next
        end
        account.transactions.create! comment: record['Comment'],
                                   total: record['Total'].split('$ ').last.gsub(',','').to_d,
                                   created_at: Time.parse(record['Date_Time']),
                                   user_id: 0
      rescue => e
        binding.pry
      end
    end
  end
end
