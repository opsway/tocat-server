class StatusController < ApplicationController

  def index
    messages = DbError.search_for(params[:search]).order("id").map(&:as_json)
    render json: { messages: messages, timestamp: Rails.cache.fetch(:selfcheck_last_run) }
  end

  def checked
    message = DbError.find(params[:id])
    message.update_attributes(checked: request.delete? ? false : true)
    render json: {}, status: 200
  end
end
