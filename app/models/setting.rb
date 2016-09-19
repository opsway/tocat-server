class Setting < ActiveRecord::Base
  validates_uniqueness_of :name
  def self.method_missing(method_sym, *args, &block)
    if obj = where(name: method_sym.to_s).first
      obj.value.match(/[0-9]+/) ? obj.value.to_i : obj.value
    else
      super
    end
  end
end
