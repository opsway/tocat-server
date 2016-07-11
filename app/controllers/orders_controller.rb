class OrdersController < ApplicationController
  before_action :set_order, except: [:index, :create,
                                     :new,
                                     :available_for_invoice]
  helper_method :sort


  def index
    @articles = Order.includes(:invoice, :team).search_for(params[:search]).order(sort)
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    @order = Order.includes(:invoice).find(params[:id])
    render json: @order, serializer: OrderShowSerializer
  end

  def commission
    old_commision = @order.commission
    if @order.update_attributes(commission: params[:commission])
      @order.create_activity :commission_update,
                              parameters: {changes: "#{old_commision} -> #{@order.commission}"},
                              owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def set_internal
    old_value = @order.internal_order
    @order.internal_order = true
    @order.paid = true
    if @order.save
      @order.create_activity :set_internal_order,
                              parameters: {changes: "#{old_value} -> #{@order.internal_order}"},
                              owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def remove_internal
    old_value = @order.internal_order
    if @order.handle_uninternal
      @order.create_activity :remove_internal_order,
                              parameters: {changes: "#{old_value} -> #{@order.internal_order}"},
                              owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def budgets
    if @order.task_orders.present?
      render json: @order.task_orders, each_serializer: TaskOrdersSerializer, root: "budget"
    else
      render json: {}, status: 200
    end
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      @order.create_activity :create,
                              parameters: order_params,
                              owner: User.current_user
      render json: @order, serializer: AfterCreationSerializer, status: 201
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def update
    action = Actions::Orders::Update.new(@order).call(order_params: order_params)
    if action.success?
      render json: action.order, serializer: AfterCreationSerializer, status: 200
    else
      render json: { errors: action.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @order.destroy
      PublicActivity::Activity.create! trackable: @order,
                                       key: 'order.destroy',
                                       owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def set_invoice
    if @order.update_attributes(invoice_id: params[:invoice_id])
      @order.create_activity :invoice_update,
                              recipient: @order.invoice,
                              owner: User.current_user
      @order.invoice.create_activity :orders_update,
                                     recipient: @order,
                                     owner: User.current_user
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
                              parameters: {
                                invoice_id_was: invoice_was.id,
                                invoice_external_id_was: invoice_was.external_id
                              },
                              owner: User.current_user
      invoice_was.create_activity :orders_update,
                                   recipient: nil,
                                   parameters: {
                                     order_id_was: @order.id,
                                     order_name_was: @order.name
                                   },
                                   owner: User.current_user
      render json: {}, status: 202
    else
      render json: error_builder(@order), status: :unprocessable_entity
    end
  end

  def new
    @order = Order.new
    render json: @order, serializer: OrderNewSerializer
  end

  def set_completed
    action = Actions::Orders::Complete.new(@order).call
    if action.success?
      render json: @order, serializer: AfterCreationSerializer, status: :ok
    else
      render json: { errors: action.errors }, status: :unprocessable_entity
    end
  end

  def available_for_invoice
    orders = Queries::Orders::AvailableForInvoice.call(
      limit: 1000
    )
    render json: orders
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
                           :internal_order)
    if params[:team].present?
      output.merge!({ team_id: params.try(:[], 'team').try(:[], 'id') })
    end
    if params[:order_id].present?
      output.merge!({ invoiced_budget: params[:allocatable_budget] }) unless params[:invoiced_budget].present?
    end
    output
  end
end
