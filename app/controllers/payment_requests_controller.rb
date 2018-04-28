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
      render json: error_builder(@payment_request), status: 406
    end
  end

  %w(cancel complete).each do |m|
    define_method m do
      @payment_request.send "#{m}!"
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
    user = User.current_user

    begin
      yield
      unless user == @payment_request.source || user.manager? || user.coach?
        render json: {}, status: 404
      else
        return render json: @payment_request, serializer: PaymentRequestSerializer
      end
    rescue  AASM::InvalidTransition => e
      return render json: { errors: [e.message] }, status: 406
    end
  end
end
