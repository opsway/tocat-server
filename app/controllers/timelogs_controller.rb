class TimelogsController < ApplicationController

  def index
    timelog = TimeLog::TimeLogApi.new(params)
    @success = timelog.get_worklogs

    if @success
      render json: {result: timelog.users_worklogs}, status: 200
    else
      render json: {error: timelog.error}, status: 402
    end
  end

  def create
    timelog = TimeLog::TimeLogApi.new(params)
    @success = timelog.get_worklogs

    if @success
      render json: {result: timelog.users_worklogs}, status: 200
    else
      render json: {error: timelog.error}, status: 402
    end
  end

end
