class HistoryOfChangeDailyRate < ActiveRecord::Base
  belongs_to :user

  scoped_search in: :user, on: :id, rename: :user, only_explicit: true


  def self.create_new_daily_rate_change(user)
    current_date = Date.today
    daily_rate = user.history_of_change_daily_rates.last

    if daily_rate.present?
      daily_rate.update_column(:timestamp_to, current_date)
    end

    user.history_of_change_daily_rates.create({
      daily_rate: user.daily_rate,
      timestamp_from: current_date,
      timestamp_to: nil
    })
  end
end
