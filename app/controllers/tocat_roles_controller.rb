class TocatRolesController < ApplicationController
  before_filter :find_role, :only => [:update, :destroy,:show]
  before_filter :find_permissions

  def index
    @roles = TocatRole.all
    render json: @roles, each_serializer: TocatRoleSerializer
  end

  def new
    array = []
    TocatRole.permissions.each do |r|
      array << r.second.collect {|p| p.to_sym unless p.blank? }.compact.uniq
    end
    @role = TocatRole.new({:permissions => array.flatten}, name: '')
    render json: @role, serializer: TocatRoleSerializer, status: 200
  end
  def show
    render json: @role, serializer: TocatRoleSerializer, status: 200
  end

  def create
    @role = TocatRole.new(tocat_role_params)
    if @role.save
      @role.create_activity :create, parameters: tocat_role_params, owner: User.current_user
      render json: @role, serializer: TocatRoleSerializer, status: 201
    else
      render json: error_builder(@role), status: 406
    end
  end

  def update
    p tocat_role_params
    if @role.update_attributes(tocat_role_params)
      render json: @role, serializer: TocatRoleSerializer, status: 200
    else
      render json: error_builder(@role), status: :unprocessable_entity
    end
  end

  def destroy
    @role.create_activity :destroy, 
                          parameters: params, 
                          owner: User.current_user
    if @role.destroy
      render json: {}, status: 200
    else
      render json: error_builder(@role), status: :unprocessable_entity
    end
  end

  private

 def find_role
    @role = TocatRole.find(params[:id])
  end
  def find_permissions
    @permissions = TocatRole.permissions
  end
  def tocat_role_params
    params.require(:tocat_role).permit(:name,:position,:permissions=>[])
  end
end
