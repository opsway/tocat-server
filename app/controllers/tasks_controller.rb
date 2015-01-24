class TasksController < ApplicationController
  before_action :set_task, except: [:index, :create]

  def index
    @tasks = Task.all
    render json: @tasks
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

  # def update
  #   if @task.update(task_params)
  #     render nothing: true, status: 202
  #   else
  #     render json: error_builder(@task), status: :unprocessable_entity
  #   end
  # end

  def destroy
    @task.destroy
    render nothing: true, status: 204
  end

  def set_accepted
    @task.accepted = true
    if @task.save
      render nothing: true, status: 202
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def delete_accepted
    @task.accepted = false
    if @task.save
      render nothing: true, status: 202
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_resolver
    user = User.where(id: params[:user_id])
    if user.present?
      @task.user = user.first
      if @task.save
        render nothing: true, status: 202
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
      render nothing: true, status: 202
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def budgets
    if @task.task_orders.present?
      render json: @task.task_orders, each_serializer: TaskOrdersSerializer, root: "budget"
    else
      render nothing: true, status: 204
    end
  end

  def set_budgets
    errors = {}
    #binding.pry
    params[:budget].each do |record|
      db_record = TaskOrders.where(task_id: @task.id, order_id: record[1]['order_id']).first
      if db_record.present?
        db_record.budget = record[1]['budget']
        errors[record[1]['order_id']] = db_record.errors[:base] unless db_record.save
      else
        new_db_record = @task.task_orders.new order_id: record[1]['order_id'],
                                              budget: record[1]['budget']
        errors[record[1]['order_id']] = new_db_record.errors[:base] unless new_db_record.save
      end
    end
    if errors.empty?
      render json: {}, status: 200
    else
      render json: errors, status: 406
    end
  end

  def orders
    render json: @task.orders, each_serializer: OrderSerializer
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.permit(:external_id)
  end
end
