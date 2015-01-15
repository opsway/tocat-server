Rails.application.routes.draw do
  namespace :v1 do
    resources :order,
              :controller => "orders",
              :path => 'order',
              :defaults => {:format => 'json'}
    post '/order/:id/invoice', to: 'orders#set_invoice', as: 'set_invoice'
    delete '/order/:id/invoice', to: 'orders#delete_invoice', as: 'delete_invoice'
    post '/order/:id/paid', to: 'orders#set_paid', as: 'set_paid'
    delete '/order/:id/paid', to: 'orders#set_unpaid', as: 'set_unpaid'
    get '/order/:id/suborder', to: 'orders#suborders', as: 'suborders'
    post '/order/:id/suborder', to: 'orders#create_suborder', as: 'new_suborder'

    resources :team,
              :controller => "teams",
              :path => "team",
              :defaults => {:format => 'json'},
              :only => [:index, :show]
    get '/team/:id/balance', to: 'teams#balance_account', as: 'team_balance'
    get '/team/:id/income', to: 'teams#income_account', as: 'team_income'
  end
end
