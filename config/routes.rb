Rails.application.routes.draw do
  resources :order,
            controller: 'orders',
            path: 'orders',
            defaults: { format: 'json' }

  post '/orders/:id/invoice',
       to: 'orders#set_invoice',
       as: 'set_invoice',
       format: 'json'

  delete '/orders/:id/invoice',
         to: 'orders#delete_invoice',
         as: 'delete_invoice',
         format: 'json'

  get '/orders/:id/suborder',
      to: 'orders#suborders',
      as: 'suborders',
      format: 'json'

  post '/orders/:id/suborder',
       to: 'orders#create_suborder',
       as: 'new_suborder',
       format: 'json'

  resources :team,
            controller: 'teams',
            path: 'teams',
            defaults: { format: 'json' },
            only: [:index, :show]

  resources :transaction,
            controller: 'transactions',
            path: 'transactions',
            defaults: { format: 'json' },
            only: [:index, :show]

  resources :user,
            controller: 'users',
            path: 'users',
            defaults: { format: 'json' },
            only: [:index, :show]

  resources :task,
            controller: 'tasks',
            path: 'tasks',
            defaults: { format: 'json' },
            only: [:index, :create, :show]

  post '/tasks/:id/accept',
       to: 'tasks#set_accepted',
       as: 'task_set_accepted',
       format: 'json'

  delete '/tasks/:id/accept',
         to: 'tasks#delete_accepted',
         as: 'task_remove_accepted',
         format: 'json'

  post '/tasks/:id/resolver',
       to: 'tasks#set_resolver',
       as: 'task_set_resolver',
       format: 'json'

  delete '/tasks/:id/resolver',
         to: 'tasks#delete_resolver',
         as: 'task_remove_resolver',
         format: 'json'

  get '/tasks/:id/budget',
      to: 'tasks#budgets',
      as: 'task_get_budget',
      format: 'json'

  post '/tasks/:id/budget',
       to: 'tasks#set_budgets',
       as: 'task_set_budget',
       format: 'json'

  get '/tasks/:id/orders',
      to: 'tasks#orders',
      as: 'task_get_orders',
      format: 'json'

  resources :invoice,
            controller: 'invoices',
            path: 'invoices',
            defaults: { format: 'json' }

  post '/invoices/:id/paid',
       to: 'invoices#set_paid',
       as: 'invoice_set_paid',
       format: 'json'

  delete '/invoices/:id/paid',
         to: 'invoices#delete_paid',
         as: 'invoice_remove_paid',
         format: 'json'
  match '*path', to: 'application#no_method', via: :all
end
