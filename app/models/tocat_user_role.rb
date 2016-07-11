class TocatUserRole < ActiveRecord::Base
  belongs_to :tocat_role, class_name: 'TocatRole'
  belongs_to :user, class_name: 'User'
end
