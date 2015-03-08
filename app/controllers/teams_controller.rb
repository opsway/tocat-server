class TeamsController < ApplicationController
  before_action :set_team, except: [:index]

  def index
    @teams = Team.all
    render json: @teams
  end

  def show
    render json: @team, serializer: TeamShowSerializer
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end
end
