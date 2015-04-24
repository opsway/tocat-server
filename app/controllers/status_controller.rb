require_relative '../../lib/self_check'
class StatusController < ApplicationController

  def selfcheck
    messages = SelfCheck.instance.start
    render json: { messages: messages }
  end
end
