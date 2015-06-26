class TaskSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :external_id, :accepted, :paid, :review_requested, :links, :budget, :resolver

  private
  def budget
    object.budget.to_f
  end

  def resolver
    user = object.user
    data = {}
    if user.present?
      data[:name] = user.name
      data[:href] = user_path(user)
      data[:id] = user.id
    end
    data
  end

  def links
    data = []
    link_to_self = {}
    link_to_self[:href] = task_path(object)
    link_to_self[:rel] = 'self'
    data << link_to_self
    link_to_external = {}
    link_to_external[:href] = object.external_url
    link_to_external[:rel] = 'external'
    data << link_to_external
  end
end
