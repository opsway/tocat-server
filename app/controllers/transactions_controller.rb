class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index]

  def index
    user = User.current_user
    @articles = Transaction.includes(:account).search_for(params[:search]).order(sort)

    if params[:user].present? && (user.manager? || user.coach? || user.tocat_role_admin?)
      account_name = Account.find(params[:user]).name
      account_ids = Account.where(name: account_name).pluck :id
      @articles = @articles.where(account_id: account_ids)
    else
      if user.manager? && !user.coach? && (user.tocat_role_manager? || user.tocat_role_admin?)
        team_members_ids = User.where(team_id: user.team.id).ids
        @articles = @articles.where(user_id: team_members_ids)
      elsif !user.manager? && !user.coach? && user.tocat_role_dev?
        user_accounts = Account.where(accountable_id: user.id).pluck :id
        @articles = @articles.where(account_id: user_accounts)
      end
    end
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    render json: @transaction, serializer: TransactionShowSerializer
  end

  private

  def set_transaction
    @transaction = Transaction.includes(account: :accountable).find(params[:id])
  end
end
