
namespace :status do
  task selfcheck: :environment do
    SelfCheck.instance.start
  end
end
