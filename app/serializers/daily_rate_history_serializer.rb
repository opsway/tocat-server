class DailyRateHistorySerializer < ActiveModel::Serializer
  attributes :id, :daily_rate, :user, :timestamp_from, :timestamp_to

  private

  def user
    data = {}
    data[:login] = object.user.login
    data
  end
end
