class TimelogsController < ApplicationController

  def index
    timelog = TimeLog::TimeLogApi.new(params)
    @success = timelog.get_worklogs

    if @success
      render json: {result: timelog.users_worklogs}, status: 200
    else
      render json: {error: timelog.error}, status: 406
    end
  end

  def create
    leave = TimeLog::ZohoLeaveApi.new(params)

    @leave_status = leave.create_leave

    if @leave_status
      render json: { result: leave.message}, status: 201
    else
      render json: {error: leave.error}, status: 406
    end
  end
end
