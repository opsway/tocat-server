class TeamsController < ApplicationController
  before_action :set_team, except: [:index, :create]

  def index
    @teams = Team.all
    render json: @teams
  end

  def show
    render json: @team, serializer: TeamShowSerializer
  end

  def create
    @team = Team.new(team_params)
    if @team.save
      @team.create_activity :create,
                            parameters: team_params
      render json: @team, serializer: TeamShowSerializer, status: 201
    else
      render json: error_builder(@team), status: 406
    end
  end

  def update
    team_attr = {}
    team_attr['name'] = @team.name
    team_attr['manager'] = @team.manager.try(:id)
    if @team.update(team_params)
      manager_id = params[:team][:manager].try(:to_i)
      @team.change_manager(manager_id) if @team.manager.try(:id) != manager_id
      @team.create_activity :update,
                            parameters: {changes: HashDiff.diff(team_attr, team_params)}
      render json: @team, serializer: TeamShowSerializer, status: 200
    else
      render json: error_builder(@team), status: 406
    end
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    output = params.require(:team).permit(:name, :default_commission)
    output
  end
end
