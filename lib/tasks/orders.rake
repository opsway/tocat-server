namespace :orders do
  desc "Rake task for transfer budget without commission from teams(couch money account) Pac-man and NFS to Growth Fund"
  
  task transfer_budget: :environment do  
    Order.where(completed: true, budget_transfered_to_growth_fund: false, team_id: [7,8]).each do |order|
      begin
        order.transfer_money_to_growth_fund_from_pacman_and_nfs
      rescue => e
        puts "Exception: #{e}. Backtrace: #{e.backtrace}"
      end
    end
  end
end
