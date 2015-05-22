require_relative '../zoho/api'

namespace :zoho do
  task :transactions => :environment do
    User.all.each do |user|
      accounts = RedmineTocatApi.get_user_accounts(user)
      accounts.each do |account|
        account_ = nil
        transactions = RedmineTocatApi.get_transactions(account["ID"])
        if transactions == nil
          puts "No transactions was founded for #{account["Name"]}"
          next
        end
        transactions.each do |transaction|
          if transaction["Account"].split.last == 'Balance'
            account_ = user.balance_account
          else
            account_ = user.income_account
          end
          account_.transactions.create! comment: transaction['Comment'],
                                       total: transaction['Total'].split('$ ').last.gsub(',','').to_d,
                                       created_at: Time.parse(transaction['Date_Time']),
                                       user_id: 0

        end
        puts "#{account_.transactions.count} transactions was created for #{user.name} #{account_.account_type} account"
      end
    end

    Team.all.each do |group|
      accounts = RedmineTocatApi.get_user_accounts(group)
      accounts.each do |account|
        account_ = nil
        transactions = RedmineTocatApi.get_transactions(account["ID"])
        if transactions == nil
          puts "No transactions was founded for #{account["Name"]}"
          next
        end
        transactions.each do |transaction|
          if transaction["Account"].split.last == 'Balance'
            account_ = group.balance_account
          else
            account_ = group.income_account
          end
          account_.transactions.create! comment: transaction['Comment'],
                                       total: transaction['Total'].split('$ ').last.gsub(',','').to_d,
                                       created_at: Time.parse(transaction['Date_Time']),
                                       user_id: 0

        end
        puts "#{account_.transactions.count} transactions was created for #{group.name} #{account_.account_type} account"
      end
    end
  end

  task :check_orders => :environment do
    orders = RedmineTocatApi.get_orders
    orders.each do |z_order|
      order = Order.where(name:z_order["Comment"]).first
      puts "Order #{z_order["Comment"]} has wrong paid status" if z_order["Paid"] != order.paid
    end
  end

  task :complete_orders => :environment do
    Transaction.transaction do
      completed_ids = Order.where(completed: true).where(parent_id: nil).ids
      Order.where(completed: true).all.each { |o| o.update_column(:completed, false) }
      Transaction.where("comment LIKE '%completed%'").destroy_all
      completed_ids.each do |id|
        order = Order.find(id)
        result = order.update_attributes(completed:true)
        puts order.id unless result
      end
    end
  end

  task :rename_completed_transactions => :environment do
    orders = RedmineTocatApi.get_orders
    orders.each do |z_order|
      order = Order.where(name: z_order["Comment"]).first
      if order.present?
        number = z_order['Number']
        transactions = Transaction.where("comment LIKE '%completed% %#{number}'")
        transactions.each do |t|
          type = t.comment.split.first.downcase
          if type == 'un-completed'
            t.update_attributes(comment: "Order ##{order.id}: '#{order.name}' was uncompleted")
          elsif type == 'completed'
            t.update_attributes(comment: "Order ##{order.id}: '#{order.name}' was completed")
          else
            puts "#{t.id} cant be processed!"
          end
        end
      end
    end
  end
end
