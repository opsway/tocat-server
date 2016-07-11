#  FIXME refactor this!!!

Rails.application.routes.draw do
  get 'acl' => 'acl#acl', defaults: {format: 'json'}

  get 'activity/index'

  #orders
  resources :order,
            path: 'orders',
            controller: 'orders',
            defaults: { format: 'json' },
            only: [:index, :new, :create] do
    get 'parent_auto_complete', on: :collection
    get 'available_parents', on: :collection
    get 'available_for_invoice', on: :collection
  end
          
  resources :balance_transfers, only: [:create, :index]
  resources :balance_transfer, only: [:show], controller: 'balance_transfers'
  resources :transfer_requests, defaults: { format: 'json' }, only: [:create, :index]
  resources :transfer_request, defaults: {format: 'json'}, only: [:show, :destroy], controller: 'transfer_requests' do
    post 'pay', on: :member
  end
  
  resources :payment_requests, only: [:create, :index]
  resources :payment_request, only: [:show, :update], controller: :payment_requests do
    member do
      post 'approve'
      post 'cancel'
      post 'reject'
      post 'complete'
      post 'dispatch', to: 'payment_requests#dispatch_my'
    end
  end

  resources :roles,
            path: 'roles',
            controller: 'roles',
            defaults: { format: 'json' },
            only: [:index]

  resources :order,
            path: 'order',
            controller: 'orders',
            defaults: { format: 'json' },
            only: [:show, :update, :destroy] do

    post 'internal', to: 'orders#set_internal', as: 'set_internal', format: 'json'
    delete 'internal', to: 'orders#remove_internal', as: 'remove_internal', format: 'json'
    post 'commission', to: 'orders#commission', as: 'commission', format: 'json'
    post 'invoice', to: 'orders#set_invoice', as: 'set_invoice', format: 'json'
    delete 'invoice', to: 'orders#delete_invoice', as: 'delete_invoice', format: 'json'
    post 'complete', to: 'orders#set_completed', as: 'set_completed', format: 'json'
    get 'budget', to: 'orders#budgets', format: 'json'

  end

  #activity
  resources :activity,
            path: 'activity',
            controller: 'activity',
            defaults: { format: 'json' }

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
            only: [:show, :update, :create]

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
            only: [:index, :create, :destroy, :me]

  resources :user,
            path: 'user',
            controller: 'users',
            defaults: { format: 'json' },
            only: [:show, :update, :destroy] do
    post 'add_payment', to: 'users#add_payment', as: 'add_payment', format: 'json'
    post 'set_role', format: 'json'
  end

  #teams
  resources :team,
            path: 'teams',
            controller: 'teams',
            defaults: { format: 'json' },
            only: [:index, :create, :show, :update]

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

    post 'expenses', to: 'tasks#set_expenses', as: 'set_expenses', format: 'json'
    delete 'expenses', to: 'tasks#delete_expenses', as: 'delete_expenses', format: 'json'
    post 'accept', to: 'tasks#set_accepted', as: 'set_accepted', format: 'json'
    delete 'accept', to: 'tasks#delete_accepted', as: 'remove_accepted', format: 'json'
    post 'resolver', to: 'tasks#set_resolver', as: 'set_resolver', format: 'json'
    delete 'resolver', to: 'tasks#delete_resolver', as: 'remove_resolver', format: 'json'
    get 'budget', to: 'tasks#budgets', as: 'get_budget', format: 'json'
    post 'budget', to: 'tasks#set_budgets', as: 'set_budget', format: 'json'
    get 'orders', to: 'tasks#orders', as: 'get_orders', format: 'json'
    post 'review', to: 'tasks#handle_review_request', as: 'request_review', format: 'json'
    delete 'review', to: 'tasks#handle_review_request', as: 'reviewed', format: 'json'
  end
  #tocat (acl) roles
  resources :tocat_roles,
            :path => 'tocat_roles',
            controller: 'tocat_roles',
            defaults: { format: 'json' },
            only: [:index,:create, :new]
  resources :tocat_roles,
            :path => 'tocat_role',
            controller: 'tocat_roles',
            defaults: { format: 'json' },
            only: [:show,:destroy,:update]


  #invoices
  resources :invoice,
            path: 'invoices',
            controller: 'invoices',
            defaults: { format: 'json' },
            only: [:index, :create, :update]
  resources :invoice,
            path: 'invoice',
            controller: 'invoices',
            defaults: { format: 'json' },
            only: [:show, :update, :destroy] do
    post 'paid', to: 'invoices#set_paid', as: 'invoice_set_paid', format: 'json'
    delete 'paid', to: 'invoices#delete_paid', as: 'invoice_remove_paid', format: 'json'
  end

  match '/status', to: 'status#index', via: :get
  match '/status/:id/checked', to: 'status#checked', via: [:put, :post, :delete]

  match '/authenticate' => 'authentication#authenticate', via: [:post, :get], as: :authenticate

  match '*path', to: 'application#no_method', via: :all
end
