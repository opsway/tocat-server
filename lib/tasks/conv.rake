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

  task :orders => :environment do
    start_date = Date.parse('1/10/2015').to_datetime
    #Order.where(id: [1084, 1073]).update_all(completed: false)
    Transaction.where(id: [45831,45832,45833,45829,45830]).delete_all # for 1084
    Transaction.where(id: [45837,45835,45836]).delete_all # for 1073
    Transaction.where(id: [45815, 45816, 45817, 45813, 45814]).delete_all # for 1059
    Transaction.where(id: [45694,45696,45695,45692,45693]).delete_all # for 1025
    
    orders_for_close_old = [1026, 1041, 1043, 1049, 1070, 1073, 1084, 1086, 321, 477 , 499, 529, 581, 584, 738, 739, 819, 950, 993, 783, 854, 891, 930, 932,967, 1064, 1083, 1034,783,812,854,891,930,932,967, 1025, 1059]
    
    orders_for_close_new = [1076, 1092, 1160, 1163, 1216, 1220, 1256, 1257, 1273, 1162, 1091, 1173, 1224, 1257, 1273]
    
    orders_for_close_old.each do |o_id|
     p o_id
     order = Order.find o_id
     Transaction.where("comment like 'Order ##{o_id} w%'").where('created_at >= ?',start_date).update_all(created_at: start_date - 1.minute)
      order.sub_orders.each do |sub|
        Transaction.where("comment like 'Order ##{sub.id} w%'").where('created_at >= ?',start_date).update_all(created_at: start_date - 1.minute)
      end
    end

    Order.where(id: orders_for_close_new).update_all(completed: false)
    Order.where(parent_id: orders_for_close_new).update_all(completed: false)
    orders_for_close_new.each do |o_id| 
      order = Order.find o_id
      if order.parent_id
        order = order.parent 
        order.update_column(:completed, false)
      end
      order.order_transactions.delete_all
      order.sub_orders.each do |sub|
        sub.order_transactions.delete_all
      end

      order.completed = true
      order.save
    end
  end
end
