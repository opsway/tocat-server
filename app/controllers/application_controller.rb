class ApplicationController < ActionController::API
  include ActionController::Serialization

  def default_serializer_options
    { root: false }
  end

  def error_builder(object)
    if object.errors[:base][0].nil?
      message = object.errors.first.second
    else
      message = object.errors[:base][0]
    end
    { error: 'ORDER_ERROR', message: message }
  end
end
