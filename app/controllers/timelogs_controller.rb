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

    if params[:zoho_approved].present?
      @leave_status = leave.zoho_approved_transactions
    else
      @leave_status = leave.create_leave
    end

    if @leave_status
      render json: { result: leave.message}, status: 201
    else
      render json: {error: leave.error}, status: 406
    end
  end

  def issues_summary
    issue = TimeLog::JiraApi.new(params)
    @success = issue.issues_summary

    if @success
      render json: {result: issue.issue_data}, status: 201
    else
      render json: {error: issue.message}, status: 406
    end
  end
end
