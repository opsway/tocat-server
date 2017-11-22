class CreateHistoryOfChangeDailyRates < ActiveRecord::Migration
  def change
    create_table :history_of_change_daily_rates do |t|
      t.decimal :daily_rate, precision: 5, scale: 2
      t.references :user, index: true
      t.date :timestamp_from
      t.date :timestamp_to

      t.timestamps null: false
    end
    add_foreign_key :history_of_change_daily_rates, :users
  end
end
