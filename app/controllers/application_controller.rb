class ApplicationController < ActionController::API
  rescue_from ActionController::RoutingError, with: :render_404_or_405
  rescue_from ActionController::UnknownHttpMethod, with: :render_404_or_405
  #rescue_from StandardError, with: :render_405
  #rescue_from Exception, with: :render_405
  #before_filter :check_format
  include ActionController::Serialization

  attr_reader :current_user
  helper_method :current_user
  hide_action :default_serializer_options
  hide_action :error_builder

  before_action :authenticate_user!


  def default_serializer_options
    { root: false }
  end

  def error_builder(object)
    case object.class.name
    when 'Order'
      messages = object.errors.messages.values.flatten
    when 'Task'
      messages = object.errors.messages.values.flatten
    else
      messages = object.errors.full_messages
    end
    { errors: messages }
  end

  def no_method
    path  = '/' unless params[:path]
    raise ActionController::RoutingError.new(path)
  end

  private

  def set_current_user
    User.current_user = User.find_by_name(params[:current_user]) if params[:current_user]
    yield
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    User.current_user = nil
  end

  def sort
    if params[:sort].present?
      order = []
      query = params[:sort].split(', ')
      [*query].each do |option|
        direction = (option =~ /desc$/) ? 'desc' : 'asc'
        column = option.split(':').first
        if controller_name.classify.constantize.column_names.include?(column)
          order << "#{column} #{direction}"
        end
      end
      order.join(', ')
    else
      "#{controller_name.classify.downcase.pluralize}.created_at desc"
    end
  end

  def render_404_or_405
    recognized_path = Rails.application.routes.recognize_path(request.env['ORIGINAL_FULLPATH'])
    if recognized_path[:action] != 'no_method'
      render json: {}, status: 405
    else
      render json: {}, status: 404
    end
  end

  def authenticate_user!
    action = Actions::AuthenticateRequest.new(request: request).call
    @current_user = action.user
    render json: { errors: 'Not Authorized' }, status: :unauthorized unless @current_user
  end
end
