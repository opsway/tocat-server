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
  
  private
  
  def payment_params
    payment_attr = params.require(:payment_request).permit(:total, :description, :source_account_id)
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
