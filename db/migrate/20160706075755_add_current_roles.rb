require 'csv'
class AddCurrentRoles < ActiveRecord::Migration
  def change
    f= File.read(Rails.root.join('db','migrate', 'tocat_roles.sql'))
    f.each_line do |l|
      execute l
    end
  end
end
