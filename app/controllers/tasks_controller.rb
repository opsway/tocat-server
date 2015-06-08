class TasksController < ApplicationController
  before_action :set_task, except: [:index, :create]

  def index
    @articles = Task.search_for(params[:search]).order(sort)
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    render json: @task, serializer: TaskShowSerializer
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      @task.create_activity :create, parameters: task_params
      render json: @task, serializer: AfterCreationSerializer, status: 201
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_accepted
    if @task.update_attributes(accepted: true)
      @task.create_activity :accepted_update,
                               parameters: { old: !@task.accepted,
                                             new: @task.accepted }
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def delete_accepted
    if @task.update_attributes(accepted: false)
      @task.create_activity :accepted_update,
                               parameters: { old: !@task.accepted,
                                             new: @task.accepted }
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_resolver
    if @task.update_attributes(user_id: params[:user_id])
      @task.create_activity :resolver_update, recipient: @task.resolver
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def delete_resolver
    if @task.update_attributes(user_id: nil)
      @task.create_activity :resolver_update, recipient: nil
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
    budget_was = @task.task_orders.each(&:serializable_hash)
    TaskOrders.transaction do
      messages = []
      begin
        @task.task_orders.destroy_all
        @task.update(budgets)
        @task.recalculate_paid_status! # FIXME
      rescue
      end
      @task.task_orders.each do |task_order|
        if task_order.errors.present?
          messages << task_order.errors.full_messages
        end
      end
      if messages.empty?
        @task.create_activity :budget_update,
                                 parameters: { old: budget_was,
                                               new: @task.task_orders.each(&:serializable_hash) }
        render json: {}, status: 200
      else
        render json: { errors: messages.flatten }, status: :unprocessable_entity
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
        @task = Task.includes(user: :team).find(params[:task_id])
      else
        @task = Task.includes(user: :team).find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      return render json: {}, status: 404
    end
  end

  def task_params
    params.permit(:external_id, :accepted, budget: [:order_id, :budget])
  end
end
