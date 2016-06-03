class PaymentRequestsController < ApplicationController
  before_filter :find_request, except: [:index, :create]
  around_filter :process_errors, except: [:index, :create]
  helper_method :sort

  def index
    @articles = PaymentRequest.search_for(params[:search]).order(sort)
    @articles = @articles.where(source_id: params[:source]) if params[:source].present?
    paginate json: @articles, per_page: params[:limit]
  end
  
  def show
  end
  
  def update
    if @payment_request.update update_params
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
  
  def approve
    @payment_request.approve!
  end
  
  def cancel
    @payment_request.cancel!
  end
  
  def reject
    @payment_request.reject!
  end
  
  def complete
    @payment_request.complete!
  end
  
  def dispatch_my
    @payment_request.dispatch!
  end
  private
  
  def payment_params
    payment_attr = params.require(:payment_request).permit(:total, :description, :currency)
    if params[:payment_request][:special].present?
      payment_attr[:payment_request].merge({salary_account_id: User.find(params[:user_id]).income_account.id})
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
      return render json: { errors: e.message }, status: 406
    end
  end
end
