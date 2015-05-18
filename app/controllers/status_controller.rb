class StatusController < ApplicationController
  def selfcheck
    report = Selfcheckreport.last
    render json: { messages: report.messages, timestamp: report.created_at }
  end
end
