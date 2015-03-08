class TasksController < ApplicationController
  before_action :set_task, except: [:index, :create]

  def index
    @filterrific = initialize_filterrific(
    Task,
    params
    ) or return

    @tasks = @filterrific.find
    paginate json: @tasks, per_page: params[:limit]
  end

  def show
    render json: @task, serializer: TaskShowSerializer
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      render json: @task, serializer: AfterCreationSerializer, status: 201
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_accepted
    @task.accepted = true
    @task.paid = true
    if @task.save
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def delete_accepted
    @task.accepted = false
    @task.paid = false
    if @task.save
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_resolver
    user = User.where(id: params[:user_id])
    if user.present?
      @task.user = user.first
      if @task.save
        render json: {}, status: 200
      else
        render json: error_builder(@task), status: :unprocessable_entity
      end
    else
      render json: { user: 'Must exists' }, status: :unprocessable_entity
    end
  end

  def delete_resolver
    @task.user_id = nil
    if @task.save
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def budgets
    if @task.task_orders.present?
      render json: @task.task_orders, each_serializer: TaskOrdersSerializer, root: "budget"
    else
      render json: {}, status: 200
    end
  end

  def set_budgets
    budgets = {}
    budgets[:task_orders_attributes] = task_params[:budget]
    passed_ids = []
    task_params[:budget].each do |record|
      passed_ids << record['id']
    end
    @task.task_order_ids.each do |record|
      unless passed_ids.include? record
        budgets[:task_orders_attributes] << {'id' => record, '_destroy' => true}
      end
    end
    TaskOrders.transaction do
      @task.update(budgets)
      errors = {}
      @task.task_orders.each do |task_order|
        if task_order.errors.present?
          errors[task_order.order_id] = task_order.errors.full_messages
        end
      end
      if errors.empty?
        render json: {}, status: 200
      else
        render json: errors, status: :unprocessable_entity
      end
    end
  end

  def orders
    render json: @task.orders, each_serializer: OrderSerializer
  end

  private

  def set_task
    if params[:task_id].present?
      @task = Task.find(params[:task_id])
    else
      @task = Task.find(params[:id])
    end
  end

  def task_params
    params.permit(:external_id, budget:[:id, :order_id, :budget, :_destroy])
  end
end
