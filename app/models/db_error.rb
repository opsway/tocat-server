class DbError < ActiveRecord::Base
  validates :alert, uniqueness: true
  
  def self.any_error?
    return true if DbError.where(checked: false).any?
    return true if StatusCheck.last.finish_run < 24.hours.ago
    false
  end

  scoped_search on: :checked, only_explicit: true, ext_method: :boolean_find

  def self.boolean_find(key, operator, value)
    return {} unless key.present? || operator.present? || value.present?
    { conditions: sanitize_sql_for_conditions(["db_errors.#{key} #{operator} ?", value.to_s.to_bool]) }
  end

  def self.store(message)
    record = DbError.where(alert: message).first
    unless record
      record = DbError.create!(alert: message)
      Rails.cache.write(:selfcheck_last_run, Time.now)
    end
    record.id
  end
end
