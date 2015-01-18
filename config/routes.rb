Rails.application.routes.draw do
  resources :order,
            controller: 'orders',
            path: 'order',
            defaults: { format: 'json' }

  post '/order/:id/invoice',
       to: 'orders#set_invoice',
       as: 'set_invoice',
       format: 'json'

  delete '/order/:id/invoice',
         to: 'orders#delete_invoice',
         as: 'delete_invoice',
         format: 'json'

  post '/order/:id/paid',
       to: 'orders#set_paid',
       as: 'set_paid',
       format: 'json'

  delete '/order/:id/paid',
         to: 'orders#set_unpaid',
         as: 'set_unpaid',
         format: 'json'

  get '/order/:id/suborder',
      to: 'orders#suborders',
      as: 'suborders',
      format: 'json'

  post '/order/:id/suborder',
       to: 'orders#create_suborder',
       as: 'new_suborder',
       format: 'json'

  resources :team,
            controller: 'teams',
            path: 'team',
            defaults: { format: 'json' },
            only: [:index, :show]

  resources :transaction,
            controller: 'transactions',
            path: 'transaction',
            defaults: { format: 'json' },
            only: [:index, :show]

  resources :user,
            controller: 'users',
            path: 'user',
            defaults: { format: 'json' },
            only: [:index, :show]

  resources :task,
            controller: 'tasks',
            path: 'task',
            defaults: { format: 'json' }

  post '/task/:id/accept',
       to: 'tasks#set_accepted',
       as: 'task_set_accepted',
       format: 'json'

  delete '/task/:id/accept',
         to: 'tasks#delete_accepted',
         as: 'task_remove_accepted',
         format: 'json'

  post '/task/:id/resolver',
       to: 'tasks#set_resolver',
       as: 'task_set_resolver',
       format: 'json'

  delete '/task/:id/resolver',
         to: 'tasks#delete_resolver',
         as: 'task_remove_resolver',
         format: 'json'

  get '/task/:id/budget',
      to: 'tasks#budgets',
      as: 'task_get_budget',
      format: 'json'

  post '/task/:id/budget',
       to: 'tasks#set_budgets',
       as: 'task_set_budget',
       format: 'json'

  get '/task/:id/order',
      to: 'tasks#orders',
      as: 'task_get_orders',
      format: 'json'
end
