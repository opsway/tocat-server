class TasksController < ApplicationController
  before_action :set_task, except: [:index, :create]

  def index
    if params[:search].present? && params[:search].include?('external_id=')
      external_id_value = params[:search].gsub('external_id=', '')
      @articles = Task.includes(:orders).includes(:user).where(external_id: external_id_value).order(sort)
    else
      @articles = Task.includes(:orders).includes(:user).search_for(params[:search]).order(sort)
    end
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    render json: @task, serializer: TaskShowSerializer
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      @task.create_activity :create, parameters: task_params, owner: User.current_user
      render json: @task, serializer: AfterCreationSerializer, status: 201
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def handle_review_request
    if @task.review_requested != request.post? && @task.update_attributes(review_requested: request.post?)
      @task.create_activity :review_updated,
                               parameters: {
                                 old: !@task.review_requested,
                                 new: @task.review_requested
                               },
                               owner: User.current_user,
                               recipient: @task.user
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_expenses
    if @task.update_attributes(expenses: true)
      @task.create_activity :expenses_update,
        parameters: {
                     old: !@task.expenses,
                     new: @task.expenses,
                    },
        owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end
  def delete_expenses
    if @task.update_attributes(expenses: false)
      @task.create_activity :accepted_update,
                               parameters: {
                                 old: !@task.expenses,
                                 new: @task.expenses,
                               },
                               owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_accepted
    if @task.update_attributes(accepted: true)
      @task.create_activity :accepted_update,
                               parameters: {
                                 old: !@task.accepted,
                                 new: @task.accepted,
                                 balance: @task.budget
                               },
                               owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def delete_accepted
    if @task.update_attributes(accepted: false)
      @task.create_activity :accepted_update,
                               parameters: {
                                 old: !@task.accepted,
                                 new: @task.accepted,
                                 balance: @task.budget
                               },
                               owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def set_resolver
    if @task.update_attributes(user_id: params[:user_id])
      @task.create_activity :resolver_update,
                               recipient: @task.resolver,
                               owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@task), status: :unprocessable_entity
    end
  end

  def delete_resolver
    if @task.update_attributes(user_id: nil)
      @task.create_activity :resolver_update, recipient: nil, owner: User.current_user
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
    action = Actions::Tasks::SetBudgets.new(@task).call(budgets: task_params[:budget])
    if action.success?
      render json: {}, status: :ok
    else
      render json: { errors: action.errors }, status: :unprocessable_entity
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
      elsif params[:external_id].present?
        @task = Task.find_by(external_id: params[:external_id])
        raise(ActiveRecord::RecordNotFound) unless @task
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
