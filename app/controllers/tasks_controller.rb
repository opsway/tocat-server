class TasksController < ApplicationController
  before_action :set_task, except: [:index, :create]

  def index
    if params[:search].present?
      tasks = Task.search_for(params[:search])
    else
      tasks = Task.all
    end

    @articles = tasks.order(sort)
    paginate json: @articles, per_page: params[:limit]
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
    if task_params[:budget].present?
      budgets[:task_orders_attributes] = task_params[:budget]
    end
    TaskOrders.transaction do
      @task.task_orders.destroy_all
      @task.update(budgets)
      messages_ = []
      @task.task_orders.each do |task_order|
        if task_order.errors.present?
          messages_ << task_order.errors.full_messages
        end
      end
      if messages_.empty?
        render json: {}, status: 200
      else
        render json: { errors: messages_.flatten }, status: :unprocessable_entity
        raise ActiveRecord::Rollback.new
      end
    end
  end

  def orders
    render json: @task.orders, each_serializer: OrderSerializer
  end

  private

  def set_task
    begin
      if params[:task_id].present?
        @task = Task.find(params[:task_id])
      else
        @task = Task.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      return render json: {}, status: 404
    end
  end

  def task_params
    params.permit(:external_id, :accepted, budget:[:order_id, :budget])
  end
end
