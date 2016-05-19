class TransferRequestsController < ApplicationController
  before_action :find_request, only: [:show, :update, :destroy, :pay]
  def index
    @articles = TransferRequest.order(sort)
    if params[:source].present?
      user = User.find params[:source]
      @articles = @articles.where(source_id: user.id)
    end
    if params[:target].present?
      user = User.find params[:target]
      @articles = @articles.where(target_id: user.id)
    end
    paginate json: @articles, per_page: params[:limit]
  end
  def show
    render json: @tr, serializer: RequestSerializer
  end

  def update
    tr_params = @tr.attributes 
    if @tr.update transfer_params
      @tr.create_activity :update,
        parameters: { changes: HashDiff.diff(tr_params, transfer_params) },
        owner: User.current_user
      render json: @tr, serializer: RequestSerializer
    else
      render json: error_builder(@tr), status: 406
    end
  end
  def pay
   @tr.state = 'paid'
   if @tr.save
      @tr.create_activity :pay,
        parameters: { total: @tr.total },
        owner: User.current_user
      render json: @tr, serializer: RequestSerializer
   else
      render json: error_builder(@tr), status: 406
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
    params.require(:transfer_request).permit(:total, :source_id, :description)
  end
  def find_request
    @tr= TransferRequest.find params[:id] 
  end
end
