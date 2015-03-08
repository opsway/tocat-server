class TaskShowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id,
             :external_id,
             :budget,
             :paid,
             :accepted,
             :resolver,
             :links
  has_many :orders

  has_many :orders

  private

  def accepted
    object.accepted
  end

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
    link_to_accepted = {}
    link_to_accepted[:href] = task_set_accepted_path(object)
    link_to_accepted[:rel] = 'accept'
    data << link_to_accepted
    link_to_resolver = {}
    link_to_resolver[:href] = task_set_resolver_path(object)
    link_to_resolver[:rel] = 'resolver'
    data << link_to_resolver
    link_to_budget = {}
    link_to_budget[:href] = task_get_budget_path(object)
    link_to_budget[:rel] = 'budget'
    data << link_to_budget
    data
  end
end
