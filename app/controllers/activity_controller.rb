class ActivityController < ApplicationController
  def index
    if params[:owner].present?
      records = PublicActivity::Activity.where(owner_type: params[:owner].humanize)
      records = records.where(owner_id: params[:owner_id].split(',')) if params[:owner_id].present?
    elsif params[:trackable].present?
      records = PublicActivity::Activity.where(trackable_type: params[:trackable].humanize)
      records = records.where(trackable_id: params[:trackable_id].split(',')) if params[:trackable_id].present?
    elsif params[:recipient].present?
      records = PublicActivity::Activity.where(recipient_type: params[:recipient].humanize)
      records = records.where(recipient_id: params[:recipient_id].split(',')) if params[:recipient_id].present?
    else
      records = PublicActivity::Activity.all
    end
    records = records.where(key: params[:key]) if params[:key].present?

    @articles = records.order(sort)
    paginate json: @articles, per_page: params[:limit]
  end
end
