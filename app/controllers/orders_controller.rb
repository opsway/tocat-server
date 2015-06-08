class OrdersController < ApplicationController
  before_action :set_order, except: [:index, :create, :create_suborder, :new]
  helper_method :sort


  def index
    @articles = Order.includes(:invoice, :team).search_for(params[:search]).order(sort)
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    @order = Order.includes(:invoice).find(params[:id])
    render json: @order, serializer: OrderShowSerializer
  end

  def edit
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      @order.create_activity :create, parameters: order_params
      render json: @order, serializer: AfterCreationSerializer, status: 201
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def update
    order_attr = {}
    order_attr['name'] = @order.name
    order_attr['description'] = @order.description
    order_attr['invoiced_budget'] = @order.invoiced_budget.to_s
    order_attr['allocatable_budget'] = @order.allocatable_budget.to_s
    order_attr['team_id'] = @order.team_id.to_s
    if @order.update(order_params)
      @order.create_activity :update, parameters: { changes: HashDiff.diff(order_attr, order_params) }
      render json: @order, serializer: AfterCreationSerializer, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def destroy
    if @order.destroy
      PublicActivity::Activity.create! owner: @order, key: 'order.destroy'
      render json: {}, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def set_invoice
    if @order.update_attributes(invoice_id: params[:invoice_id])
      @order.create_activity :invoice_update, recipient: @order.invoice
      @order.invoice.create_activity :orders_update, recipient: @order
      render json: {}, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def delete_invoice
    invoice_was = @order.invoice
    if @order.update_attributes(invoice_id: nil)
      @order.create_activity :invoice_update,
                              recipient: nil,
                              parameters: { invoice_id_was: invoice_was.id,
                                            invoice_external_id_was: invoice_was.external_id }
      invoice_was.create_activity :orders_update,
                                   recipient: nil,
                                   parameters: {
                                     order_id_was: @order.id,
                                     order_name_was: @order.name }
      render json: {}, status: 202
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def create_suborder
    @order = Order.new(order_params)
    if @order.save
      @order.create_activity :create, parameters: order_params
      render json: @order, serializer: AfterCreationSerializer, status: 201
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def new
    @order = Order.new
    render json: @order, serializer: OrderShowSerializer
  end

  def set_completed
    if @order.completed == true
      return render json: { errors: ['Can not complete already completed order'] }, status: :unprocessable_entity # FIXME
    end
    if @order.update_attributes(completed: true)
      @order.create_activity :completed_update,
                               parameters: { new: @order.completed,
                                             old: !@order.completed }
      render json: @order, serializer: AfterCreationSerializer, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def remove_completed
    if @order.completed == false
      return render json: { errors: ['Can not un-complete order, that is not completed'] }, status: :unprocessable_entity # FIXME
    end
    if @order.update_attributes(completed: false)
      @order.create_activity :completed_update,
                               parameters: { new: @order.completed,
                                             old: !@order.completed }
      render json: @order, serializer: AfterCreationSerializer, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  private

  def set_order
    if params[:order_id].present?
      @order = Order.includes(:team, :invoice).find(params[:order_id])
    else
      @order = Order.includes(:team, :invoice).find(params[:id])
    end
  end

  def order_params
    output = params.permit(:name,
                           :description,
                           :team,
                           :invoiced_budget,
                           :allocatable_budget,
                           :invoice_id,
                           :parent_id)
    if params[:team].present?
      output.merge!({ team_id: params.try(:[], 'team').try(:[], 'id') })
    end
    if params[:order_id].present?
      output.merge!({ parent_id: params.try(:[], 'order_id')})
      output.merge!({ invoiced_budget: params[:allocatable_budget] }) unless params[:invoiced_budget].present?
    end
    output
  end
end
