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
  #     render json: {}, status: 202
  #   else
  #     render json: error_builder(@task), status: :unprocessable_entity
  #   end
  # end

  def destroy
    @task.destroy
    render json: {}, status: 200
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
    invalid_record = nil
    saved_records = []
    params[:budget].each do |record|
      db_record = TaskOrders.where(task_id: @task.id, order_id: record[1]['order_id']).first
      if db_record.present?
        db_record.budget = 1
        db_record.save
        db_record.budget = record[1]['budget']
        if db_record.save
          saved_records << db_record
        else
          invalid_record = db_record
        end
      else
        new_db_record = @task.task_orders.new order_id: record[1]['order_id'],
                                              budget: record[1]['budget']
        if new_db_record.save
          saved_records << new_db_record
        else
          invalid_record = new_db_record
        end
      end
    end
    if invalid_record.nil?
      render json: {}, status: 200
    else
      saved_records.each { |r| r.destroy }
      render json: error_builder(invalid_record, 'TASK'), status: 422
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
