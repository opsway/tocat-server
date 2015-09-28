class UsersController < ApplicationController
  before_action :set_user, except: [:index, :create]

  def index
    @articles = User.search_for(params[:search]).order(sort)
    paginate json: @articles, per_page: params[:limit]
  end

  def pay_bonus
    if @user.paid_bonus(params[:income].to_f, params[:bonus].to_f)
      render json: {}, status: 201
    else
      render json: error_builder(@user), status: :unprocessable_entity
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
      render json: error_builder(@user), status: :unprocessable_entity
    end
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
      render json: error_builder(@user), status: :unprocessable_entity
    end
  end


  def balance_account
    render json: @user.balance_account
  end

  def income_account
    render json: @user.income_account
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

  def user_params
    output = params.permit(:name,
                           :login,
                           :team,
                           :daily_rate,
                           :role)
    if params[:team].present?
      output.merge!({ team_id: params.try(:[], 'team').try(:[], 'id') })
    end
    if params[:role].present?
      output.merge!({ role_id: params.try(:[], 'role').try(:[], 'id') })
    end
    output
  end
end
