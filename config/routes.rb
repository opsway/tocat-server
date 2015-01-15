Rails.application.routes.draw do
  namespace :v1 do
    resources :order,
              :controller => "orders",
              :path => 'order',
              :defaults => {:format => 'json'}
  end


end
