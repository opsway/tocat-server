class PaymentRequestsController < ApplicationController
  before_filter :find_request, except: [:index, :create, :pay_in_full]
  around_filter :process_errors, except: [:index, :create, :update]
  helper_method :sort

  def index
    if User.current_user.tocat_allowed_to?(:view_all_transfer_requests)
      @articles = PaymentRequest.search_for(params[:search]).order(sort)
    else
      account_ids = AccountAccess.where(user_id: User.current_user).select(:account_id)
      @articles = PaymentRequest.search_for(params[:search]).where(source_account_id: account_ids).order(sort)
    end
    if params[:source].present?
      @articles = @articles.where(source_account_id: params[:source]) 
    end
    if params[:created_by].present?
      @articles = @articles.where(source_id: params[:created_by]) 
    end
    @articles = @articles.where status: params[:status] if params[:status].present?
    paginate json: @articles, per_page: params[:limit]
  end
  
  def show
  end
  
  def create
    @payment_request = PaymentRequest.new payment_params
    if @payment_request.save
      render json: @payment_request, serializer: PaymentRequestSerializer
    else
      p "can't save"
      p @payment_request.errors
      render json: error_builder(@payment_request), status: 406
    end
  end
  
  %w(cancel complete).each do |m|
    define_method m do
      @payment_request.send "#{m}!"
    end
  end

  def pay_in_full
    account = Account.find(params[:account_id])
    if account.id.in? current_user.account_access.map(&:account_id)
      total_calc = account.balance
      total = account.balance < 500 ? total_calc - 5.0 : total_calc - (total_calc*Setting.external_payment_commission/100.0)
      p total.to_s
      source_id = current_user.id
      source_account_id = current_user.money_account.id
      description = "Salary pay in full from #{account.name} account #{Date.current}"
      @pay_full = PaymentRequest.new(source_id: source_id,
                               description: description,
                               source_account_id: source_account_id,
                               total: total)
      if @pay_full.save
        render json: {name: current_user.name}
      else
        render json: error_builder(@pay_full), status: 406
      end
    end
  end
  
  private

  def payment_params
    payment_attr = params.require(:payment_request).permit(:total, :description, :source_account_id, :file, :file_name)
    payment_attr
  end
  def update_params
    params.require(:payment_request).permit(:total, :description, :currency)
  end

  def find_request
    @payment_request = PaymentRequest.find params[:id]
  end
  
  def process_errors
    begin
      yield
      return render json: @payment_request, serializer: PaymentRequestSerializer
    rescue  AASM::InvalidTransition => e
      return render json: { errors: [e.message] }, status: 406
    end
  end
end
