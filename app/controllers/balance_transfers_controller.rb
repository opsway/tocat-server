class BalanceTransfersController < ApplicationController
  def index

    if User.current_user.tocat_allowed_to?(:view_all_payment_requests)
      @articles =  BalanceTransfer.order(sort)
    else
      account_ids = AccountAccess.where(user_id: User.current_user).select(:account_id)
      @articles =  BalanceTransfer.order(sort).where("source_id in (?) or target_id in (?) ", account_ids, account_ids)
    end
    if params[:source].present?
      account = Account.find params[:source]
      @articles = @articles.where(source_id: account.id)
    end
    if params[:target].present?
      account = Account.find params[:target]
      @articles = @articles.where(target_id: account.id)
    end
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    user = User.current_user
    @balance_transfer = BalanceTransfer.find(params[:id])

    unless user.accounts.include?(@balance_transfer.target) || user.manager? || user.coach?  || user.tocat_role.name == 'TOCAT Administrator'
      render json: {}, status: 404
    else
      render json: @balance_transfer, serializer: BtShowSerializer
    end
  end

  def create
    @bt = BalanceTransfer.new(transfer_params)
    if  @bt.save
      @bt.create_activity :create,
         parameters: transfer_params,
         owner: User.current_user
      render json: @bt, serializer: BtShowSerializer
    else
      render json: error_builder(@bt), status: :unprocessable_entity
    end
  end

  private
  def transfer_params
    params.require(:balance_transfer).permit(:total, :target_login, :description, :source_id, :target_id)
  end
end
