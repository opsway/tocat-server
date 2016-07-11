class TocatRoleSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :name, :position, :permissions, :links
  private
  def links
    data = {}
    if object.id
      data[:href] = tocat_role_path(object)
      data[:rel]  = 'self'
    end
    data
  end
end
