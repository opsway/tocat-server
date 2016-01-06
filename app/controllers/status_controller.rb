class StatusController < ApplicationController

  def index
    messages = DbError.search_for(params[:search]).order("id").map(&:as_json)
    if status = StatusCheck.last
      timestamp = status.finish_run || status.start_run
    else
      timestamp = 1.month.ago
    end

    render json: { messages: messages, timestamp: timestamp }
  end

  def checked
    message = DbError.find(params[:id])
    message.update_attributes(checked: request.delete? ? false : true)
    render json: {}, status: 200
  end
end
