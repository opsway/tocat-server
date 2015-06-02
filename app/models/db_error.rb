class DbError < ActiveRecord::Base
  validates :alert, uniqueness: true

  scoped_search on: :checked, only_explicit: true, ext_method: :boolean_find

  def self.boolean_find(key, operator, value)
    return {} unless key.present? || operator.present? || value.present?
    { conditions: sanitize_sql_for_conditions(["db_errors.#{key} #{operator} ?", value.to_s.to_bool]) }
  end

  def self.store(message)
    record = nil
    unless DbError.where(alert: message).any?
      record = DbError.create!(alert: message)
      Rails.cache.write(:selfcheck_last_run, Time.now)
    end
    record.id
  end
end
