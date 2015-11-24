class StatusController < ApplicationController

  def index
    messages = DbError.search_for(params[:search]).order("id").map(&:as_json)
    timestamp = Rails.cache.fetch('last_success_self_start') || 1.month.ago
    render json: { messages: messages, timestamp: timestamp }
  end

  def checked
    message = DbError.find(params[:id])
    message.update_attributes(checked: request.delete? ? false : true)
    render json: {}, status: 200
  end
end
