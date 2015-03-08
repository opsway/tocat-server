#  FIXME refactor this!!!

Rails.application.routes.draw do
  #orders
  resources :order,
            path: 'orders',
            controller: 'orders',
            defaults: { format: 'json' },
            only: [:index, :create]

  resources :order,
            path: 'order',
            controller: 'orders',
            defaults: { format: 'json' },
            only: [:show, :edit, :update, :destroy] do


    post 'invoice', to: 'orders#set_invoice', as: 'set_invoice', format: 'json'
    delete 'invoice', to: 'orders#delete_invoice', as: 'delete_invoice', format: 'json'
    get 'suborder', to: 'orders#suborders', as: 'suborders', format: 'json'
    post 'suborder', to: 'orders#create_suborder', as: 'new_suborder', format: 'json'
  end

  #teams
  resources :team,
            path: 'teams',
            controller: 'teams',
            defaults: { format: 'json' },
            only: [:index]
  resources :team,
            path: 'team',
            controller: 'teams',
            defaults: { format: 'json' },
            only: [:show]

  #transactions
  resources :transaction,
            path: 'transactions',
            controller: 'transactions',
            defaults: { format: 'json' },
            only: [:index]

  resources :transaction,
            path: 'transaction',
            controller: 'transactions',
            defaults: { format: 'json' },
            only: [:show]

  #users
  resources :user,
            path: 'users',
            controller: 'users',
            defaults: { format: 'json' },
            only: [:index]

  resources :user,
            path: 'user',
            controller: 'users',
            defaults: { format: 'json' },
            only: [ :show]

  #tasks
  resources :task,
            path: 'tasks',
            controller: 'tasks',
            defaults: { format: 'json' },
            only: [:index, :create]

  resources :task,
            path: 'task',
            controller: 'tasks',
            defaults: { format: 'json' },
            only: [:show] do

    post 'accept', to: 'tasks#set_accepted', as: 'set_accepted', format: 'json'
    delete 'accept', to: 'tasks#delete_accepted', as: 'remove_accepted', format: 'json'
    post 'resolver', to: 'tasks#set_resolver', as: 'set_resolver', format: 'json'
    delete 'resolver', to: 'tasks#delete_resolver', as: 'remove_resolver', format: 'json'
    get 'budget', to: 'tasks#budgets', as: 'get_budget', format: 'json'
    post 'budget', to: 'tasks#set_budgets', as: 'set_budget', format: 'json'
    get 'orders', to: 'tasks#orders', as: 'get_orders', format: 'json'
  end

  #invoices
  resources :invoice,
            path: 'invoices',
            controller: 'invoices',
            defaults: { format: 'json' },
            only: [:index, :create]
  resources :invoice,
            path: 'invoice',
            controller: 'invoices',
            defaults: { format: 'json' },
            only: [:show, :edit, :update, :destroy] do

    post 'paid', to: 'invoices#set_paid', as: 'invoice_set_paid', format: 'json'
    delete 'paid', to: 'invoices#delete_paid', as: 'invoice_remove_paid', format: 'json'
  end
  match '*path', to: 'application#no_method', via: :all
end
