class PaymentRequestsController < ApplicationController
  before_filter :find_request, except: [:index, :create]
  around_filter :process_errors, except: [:index, :create, :update]
  helper_method :sort

  def index
    @articles = PaymentRequest.search_for(params[:search]).order(sort)
    if params[:source].present?
      source = User.find_by_email(params[:source])
      @articles = @articles.where(source_id: source.try(:id)) 
    end
    @articles = @articles.where status: params[:status] if params[:status].present?
    paginate json: @articles, per_page: params[:limit]
  end
  
  def show
  end
  
  def update
    if @payment_request.new? && @payment_request.update(update_params)
      render json: @payment_request, serializer: PaymentRequestSerializer
    else
      render json: error_builder(@payment_request), status: 406
    end
  end
  
  def create
    @payment_request = PaymentRequest.new payment_params
    if @payment_request.save
      render json: @payment_request, serializer: PaymentRequestSerializer
    else
      render json: error_builder(@payment_request), status: 406
    end
  end
  
  %w(approve cancel reject complete).each do |m|
    define_method m do
      @payment_request.send "#{m}!"
    end
  end
  
  def dispatch_my
    @payment_request.target = User.find_by_email(params[:email])
    @payment_request.dispatch!
  end
  private
  
  def payment_params
    payment_attr = params.require(:payment_request).permit(:total, :description, :currency)
    if params[:payment_request][:special].present?
      payment_attr.merge!({salary_account_id: params[:payment_request][:salary_account_id], special: true, bonus: params[:payment_request][:bonus]})
    end
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
