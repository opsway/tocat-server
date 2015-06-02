class DbError < ActiveRecord::Base
  validates :alert, uniqueness: true

  scoped_search on: :checked, only_explicit: true, ext_method: :boolean_find

  def self.boolean_find(key, operator, value)
    { conditions: sanitize_sql_for_conditions(["db_errors.#{key} #{operator} ?", value.to_s.to_bool]) }
  end

  def self.store(message)
    unless DbError.where(alert: message).any?
      DbError.create!(alert: message)
      Rails.cache.write(:selfcheck_last_run, Time.now)
    end
  end
end
