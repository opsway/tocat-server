
namespace :status do
  task selfcheck: :environment do
    messages = SelfCheck.instance.start
    Selfcheckreport.create! messages: messages
  end
end
