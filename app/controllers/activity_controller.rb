class ActivityController < ApplicationController
  def index
    if params[:owner].present?
      records = PublicActivity::Activity.where(trackable_type: params[:owner].humanize)
      records = records.where(trackable_id: params[:owner_id].to_i) if params[:owner_id].present?
    else
      records = PublicActivity::Activity.all
    end

    @articles = records.order(sort)
    paginate json: @articles, per_page: params[:limit]
  end
end
