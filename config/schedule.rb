if ENV['CRON_JOB']
  every '*/3 * * * *' do
    rake 'shiftplanning:update_transactions' 
  end

  every '3 1 */1 * *' do
    rake 'status:selfcheck'
  end

  every '0 */1 * * *' do
    rake 'budget:parse'
  end
end
