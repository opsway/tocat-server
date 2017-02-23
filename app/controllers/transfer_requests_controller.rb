class TransferRequestsController < ApplicationController
  before_action :find_request, only: [:show, :update, :destroy, :pay]
  def index
    @articles =
      if User.current_user.tocat_allowed_to?(:view_all_payment_requests)
        TransferRequest.order(sort)
      else
        account_ids = AccountAccess.where(user_id: User.current_user).select(:account_id)
        TransferRequest.order(sort).where("source_account_id in (?) or target_account_id in (?) or payroll_account_id in (?)", account_ids, account_ids, account_ids)
      end
    if params[:source].present?
      @articles = @articles.where(source_account_id: params[:source])
    end
    if params[:target].present?
      @articles = @articles.where(target_account_id: params[:target])
    end
    if params[:state].present?
      @articles = @articles.where(state: params[:state])
    end
    paginate json: @articles, per_page: params[:limit]
  end
  def show
    render json: @tr, serializer: RequestSerializer
  end

  def pay
   @tr.state = 'paid'
   @tr.source_account_id = params[:source_account_id]
   if @tr.save
      @tr.create_activity :pay,
        parameters: { total: @tr.total },
        owner: User.current_user
      render json: @tr, serializer: RequestSerializer
   else
      render json: error_builder(@tr), status: 406
   end
  end
  
  def withdraw
    account = Account.find(params[:account_id])
    if account.id.in? current_user.account_access.map(&:account_id)
      coach = current_user.team.couch
      source_id = coach.id
      description = "Withdraw from #{account.name} account #{Date.current}"
      source_account_id = coach.money_account.id
      target_account_id = current_user.money_account.id
      @tr = TransferRequest.new(total: params[:total],
                                source_id: source_id, 
                                description: description, 
                                target_account_id: target_account_id, 
                                source_account_id: source_account_id, 
                                payroll_account_id: account.id,
                                payroll: true)
      if @tr.save
        @tr.create_activity :pay,
          parameters: { total: @tr.total },
          owner: User.current_user
        render json: {name: coach.name}

      else
        p @tr.errors
        render json: error_builder(@tr), status: 406
      end
    else
      render json: {errors: ["Only owner can withdraw account"]}, status: 406
    end
  end

  def destroy
    if @tr.destroy
      render json: {}, status: 200
    else
      render json: error_builder(@tr), status: 406
    end
  end
  
  def create
    @tr = TransferRequest.new transfer_params
    if @tr.save
      @tr.create_activity :create,
        parameters: { total: @tr.total },
        owner: User.current_user
      render json: @tr, serializer: RequestSerializer
    else
      render json: error_builder(@tr), status: 406
    end
  end
  
  private
  def transfer_params
    res = params.require(:transfer_request).permit(:total, :source_id, :description, :source_account_id, :target_account_id, :payroll)
    res[:description] = res[:description].to_s.truncate 254
    res
  end
  def find_request
    @tr= TransferRequest.find params[:id] 
  end
end
