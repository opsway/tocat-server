if ENV['CRON_JOB']
  # every '*/3 * * * *' do
  #   command 'cd /srv/tocat/ && rake shiftplanning:update_transactions' 
  # end

# every '3 1 */1 * *' do
#   command 'cd /srv/tocat && rake status:selfcheck'
# end

  every '0 */1 * * *' do
    command 'cd /srv/tocat && rake budget:parse'
  end
  
  every '59 23 28 * *' do
    command 'cd /srv/tocat/ && rake orders:transfer_budget'
  end

  # every 1.hour do
  #   command "cd /srv/tocat/lib/tasks && bash ./zoho_reports.sh"
  # end
end
