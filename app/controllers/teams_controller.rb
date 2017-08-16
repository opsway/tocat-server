class TeamsController < ApplicationController
  before_action :set_team, except: [:index, :create]

  def index
    @teams = Team.all.order('teams.active desc, teams.name asc')
    paginate json: @teams, per_page: params[:limit]
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

  def destroy
    params.permit!
    @team.create_activity :destroy,
                          parameters: params,
                          owner: User.current_user
    if @team.active
      if !@team.include_active_users?
        @team.update_column(:active,false)
      else
        render json: error_builder(@team), status: 406
      end
    else
      @team.update_column(:active,true)
    end
    render json: @team, serializer: TeamShowSerializer, status: 200
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    output = params.require(:team).permit(:name, :default_commission, :parent_id, :active)
    output
  end
end
