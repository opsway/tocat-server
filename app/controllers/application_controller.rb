class ApplicationController < ActionController::API
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from ActionController::UnknownHttpMethod, with: :render_404
  #rescue_from StandardError, with: :render_405
  #rescue_from Exception, with: :render_405
  #before_filter :check_format
  include ActionController::Serialization

  def default_serializer_options
    { root: false }
  end

  def error_builder(object, class_name = nil)
    if object.errors[:base][0].nil?
      message = object.errors.first.second
    else
      message = object.errors[:base][0]
    end
    class_name = object.class.name if class_name.nil?
    { error: "#{class_name.upcase}_ERROR", message: message }
  end

  def no_method
    path  = '/' unless params[:path]
    raise ActionController::RoutingError.new(path)
  end

  private

  def render_404
    render json: {}, status: 404
  end

  def check_format
    return true if %w(GET DELETE).include? request.method
    if request.format != Mime::JSON || request.content_type != 'application/json'
      render json: { error: 'ERROR', message: "Format #{request.content_type} not supported for #{request.path}" }
      return 0
    end
  end
end
