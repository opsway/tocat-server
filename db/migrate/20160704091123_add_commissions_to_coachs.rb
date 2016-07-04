class AddCommissionsToCoachs < ActiveRecord::Migration
  def change
    time_start = Date.parse('1 april 2016').to_time
    Transaction.where('created_at >= ?', time_start).map do |t|
      t.send :take_coach_transaction_commission
    end
  end
end
