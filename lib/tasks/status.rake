
namespace :status do
  task selfcheck: :environment do
    messages = SelfCheck.instance.transactions
    Selfcheckreport.create! messages: messages
  end
end
