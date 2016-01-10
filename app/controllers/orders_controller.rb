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
    if @order.update_attributes(internal_order: true, paid: true)
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

  def edit
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
    order_attr = {}
    order_attr['name'] = @order.name
    order_attr['description'] = @order.description
    order_attr['invoiced_budget'] = @order.invoiced_budget.to_s
    order_attr['allocatable_budget'] = @order.allocatable_budget.to_s
    order_attr['team_id'] = @order.team_id.to_s
    if @order.update(order_params)
      @order.create_activity :update,
                              parameters: {
                                changes: HashDiff.diff(order_attr, order_params)
                              },
                              owner: User.current_user
      render json: @order, serializer: AfterCreationSerializer, status: 200
    else
      render json: error_builder(@order), status: :unprocessable_entity
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

  def create_suborder
    @order = Order.new(order_params)
    if @order.save
      @order.create_activity :create, parameters: order_params, owner: User.current_user
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
                               parameters: {
                                 new: @order.completed,
                                 old: !@order.completed
                               },
                               owner: User.current_user
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
                           :internal_order,
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
