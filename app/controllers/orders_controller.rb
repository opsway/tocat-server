class OrdersController < ApplicationController
  before_action :set_order, except: [:index, :create, :create_suborder]

  def index
    @orders = Order.all
    render json: @orders
  end

  def show
    render json: @order, serializer: OrderShowSerializer
  end

  def edit
  end

  def create
    @order = Order.new(order_params)
    if params[:team].present? && params[:team][:id]
      @order.team_id = params[:team][:id]
      if @order.save
        render json: @order, serializer: AfterCreationSerializer, status: 201
      else
        render json: error_builder(@order), status: :unprocessable_entity
      end
    else
      render json: { error: 'ORDER_ERROR', message: 'Team value is missing' }, status: :unprocessable_entity
    end
  end

  def update
    if @order.update(order_params)
      render json: @order, serializer: AfterCreationSerializer, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    render json: {}, status: 200
  end

  def set_invoice
    @order.invoice = Invoice.find(params[:invoice_id])
    if @order.save
      render json: {}, status: 202
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def delete_invoice
    @order.invoice_id = nil
    if @order.save
      render json: {}, status: 202
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def set_paid
    @order.paid = true
    if @order.save
      render json: {}, status: 202
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def set_unpaid
    @order.paid = false
    if @order.save
      render json: {}, status: 202
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def suborders
    @suborders = @order.sub_orders.all
    render json: @suborders
  end

  def create_suborder
    @order = Order.new(order_params)
    unless params[:allocatable_budget]
      render json: { error: 'ORDER_ERROR', message: 'Allocatable budget is missing' }, status: :unprocessable_entity
      return 0
    end
    unless params[:team].present? && params[:team][:id].present?
      render json: { error: 'ORDER_ERROR', message: 'Team value is missing' }, status: :unprocessable_entity
      return 0
    end
    @order.team_id = params[:team][:id]
    @order.invoiced_budget = order_params[:allocatable_budget]
    @order.parent = Order.find(params[:id])
    if @order.save
      render json: @order, serializer: OrderAfterCreationSerializer, status: 201 # conflict
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.permit(:name,
                  :description,
                  :team,
                  :invoiced_budget,
                  :allocatable_budget,
                  :invoice_id)
  end
end
