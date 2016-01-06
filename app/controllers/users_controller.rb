class UsersController < ApplicationController
  before_action :set_user, except: [:index, :create]
  before_action :check_user, except: [:index, :create, :destroy, :show]

  def index
    if params[:anyuser].present?
      @articles = User.search_for(params[:search]).order('active desc, name asc')
    else
      @articles = User.search_for(params[:search]).order('users.name asc').all_active
    end
    
    if params[:limit].present? || params[:page].present? || params[:anyuser].present?
      return paginate json: @articles, per_page: params[:limit] 
    else
      render json: @articles
    end
  end

  def add_payment
    if @user.add_payment(params[:comment], params[:total])
      render json: {}, status: 201
    else
      render json: error_builder(@user), status: :unprocessable_entity
    end
  end

  def show
    render json: @user, serializer: UserShowSerializer
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.create_activity :create,
                             parameters: user_params,
                             owner: User.current_user
      render json: @user, serializer: UserShowSerializer, status: 201
    else
      render json: error_builder(@user), status: 406
    end
  end
  
  def destroy
    params.permit!
    @user.create_activity :destroy,
      parameters: params,
      owner: User.current_user
    if @user.active
      @user.update_column(:active,false)
    else
      @user.update_column(:active,true)
    end
    render json: @user, serializer: UserShowSerializer, status: 200
  end

  def update
    user_attr = {}
    user_attr['name'] = @user.name
    user_attr['login'] = @user.login
    user_attr['team'] = @user.team.to_s
    user_attr['daily_rate'] = @user.daily_rate.to_s
    user_attr['role'] = @user.role.to_s
    if @user.update(user_params)
      @user.create_activity :update,
                             parameters: {changes: HashDiff.diff(user_attr, user_params)},
                             owner: User.current_user
      render json: @user, serializer: UserShowSerializer, status: 200
    else
      render json: error_builder(@user), status: 406
    end
  end

  private

  def set_user
    begin
      if params[:user_id].present?
        @user = User.find(params[:user_id])
      else
        @user = User.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      return render json: {}, status: 404
    end
  end

  def check_user
    unless @user.active? 
      return render json: {errors: ['User is inactive']}, status: 422
    end
  end

  def user_params
    output = params.require(:user).permit(:name,
                                          :login,
                                          :daily_rate,
                                          :team_id,
                                          :role_id
                                          )
    if params[:user].try(:[],:team).present?
      output.merge!({ team_id: params[:user]['team']})
    end
    if params[:user].try(:[],:role).present?
      output.merge!({ role_id: params[:user].try(:[], :role)})
    end
    output
  end
end
