Setting.find_each do |s|
  Setting.instance_eval do
    define_method s.name do
      s.value.match(/[0-9]+/) ? obj.value.to_i : obj.value
    end
  end
end
