module V1
  class UsersController < ApplicationController
    before_action :set_user, except: [:index]

    def index
      @users = User.all
      render json: @users
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
      @user = User.find(params[:id])
    end
  end
end
