class UsersController < ApplicationController
  before_action :set_user, except: [:index]

  def index
    @articles = User.search_for(params[:search]).order(sort)
    #paginate json: @articles, per_page: params[:limit]
    render json: @articles

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
end
