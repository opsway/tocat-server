class AccountsController < ApplicationController
  def index
    @accounts = Account.search_for(params[:search])
    paginate json: @accounts, per_page: params[:limit]
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show
    @account = Account.find(params[:id])

    render json: @account
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(account_params)

    if @account.save
      render json: @account, status: :created, location: @account
    else
      render json: @account.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /accounts/1
  # PATCH/PUT /accounts/1.json
  def update
    @account = Account.find(params[:id])

    if @account.update(account_params)
      head :no_content
    else
      render json: @account.errors, status: :unprocessable_entity
    end
  end

  def add_access
    @account = Account.find(params[:id])
    @user = User.find params[:user_id]
    @account.account_accesses.find_or_create_by account: @account, user: @user 
    render json: @account, location: @account
  end
  
  def delete_access
    @account = Account.find(params[:id])
    @user = User.find params[:user_id]
    AccountAccess.where(user_id: params[:user_id], account_id: params[:id]).delete_all
    render json: @account, location: @account
  end
  def linked
    @accounts = current_user.available_accounts
    render json: @accounts
  end

  private
    
  def account_params
    params.require(:account).permit(:name, :accountable_id, :account_type)
  end
end
