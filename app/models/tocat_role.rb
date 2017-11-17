class TocatRole < ActiveRecord::Base
  serialize :permissions
  include PublicActivity::Common
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  has_many :tocat_user_roles, class_name: "TocatUserRole"
  has_many :users, through: :tocat_user_roles, class_name: "User"

  acts_as_list

  def self.check_path(request)
    paths = {}
    
# Unused!
#   paths[:tocat] = {}
#   paths[:tocat][:toggle_accepted] = :modify_accepted
#   paths[:tocat][:update_resolver] = :modify_resolver
#   paths[:tocat][:budget_dialog] = :modify_budgets
#   paths[:tocat][:save_budget_dialog] = :modify_budgets
#   paths[:tocat][:delete_budget] = :modify_budgets
#   paths[:tocat][:my_tocat] = :show_tocat_page
#   paths[:tocat][:new_payment] = :create_transactions
#   paths[:tocat][:create_payment] = :create_transactions
#   paths[:tocat][:tocat_chart_data] = :show_tocat_page
#   paths[:tocat][:request_review] = :can_request_review
#   paths[:tocat][:review_handler] = :can_review_task
#   paths[:tocat][:set_expenses] = :set_expenses
#   paths[:tocat][:remove_expenses] = :remove_expenses
    
    #roles
    paths[:roles] = {}
    paths[:roles][:index] = :is_admin

    #orders
    paths[:orders] = {}
    paths[:orders][:available_parents] = :show_orders
    paths[:orders][:available_for_invoice] = :show_orders
    paths[:orders][:index] = :show_orders
    paths[:orders][:create] = :create_orders
    paths[:orders][:new] = :create_orders
    paths[:orders][:set_internal] = :set_internal_orders
    paths[:orders][:remove_internal] = :remove_internal_orders
    paths[:orders][:commission] = :update_commission
    paths[:orders][:set_completed] = :complete_orders
    paths[:orders][:set_reseller] = :set_reseller_orders
    paths[:orders][:delete_reseller] = :unset_reseller_orders
    paths[:orders][:budgets] = :show_orders
    paths[:orders][:set_invoice] = :create_invoices
    paths[:orders][:delete_invoice] = :create_invoices
    paths[:orders][:delete_task] = :delete_task
    paths[:orders][:show] = :show_orders
    paths[:orders][:update] = :edit_orders
    paths[:orders][:destroy] = :destroy_orders
    
    #accounts
    paths[:accounts] = {}
    paths[:accounts][:new]     = :create_account
    paths[:accounts][:index]   = :view_all_accounts
    paths[:accounts][:show]    = :view_all_accounts
    paths[:accounts][:new]     = :create_account
    paths[:accounts][:edit]    = :edit_account
    paths[:accounts][:update]  = :edit_account
    paths[:accounts][:create]  = :create_account
    paths[:accounts][:add_access]  = :edit_account
    paths[:accounts][:delete_access]  = :edit_account
    paths[:accounts][:linked]  = :view_linked_accounts
    paths[:accounts][:all]  = :show_issues
    #invoices
    paths[:invoices] = {}
    paths[:invoices][:create] = :create_invoices
    paths[:invoices][:show] = :show_invoices
    paths[:invoices][:index] = :show_invoices
    paths[:invoices][:destroy] = :destroy_invoices
    paths[:invoices][:set_paid] = :paid_invoices
    paths[:invoices][:delete_paid] = :paid_invoices
    paths[:invoices][:update] = :edit_orders

    # objects history
    paths[:activity] = {}
    paths[:activity][:index] = :show_activity_feed
    paths[:activity][:create] = :show_activity_feed
    paths[:activity][:show] = :show_activity_feed
    paths[:activity][:update] = :show_activity_feed
    
    #tasks
    paths[:tasks] = {}
    paths[:tasks][:index] = :show_issues
    paths[:tasks][:create] = :show_issues
    paths[:tasks][:set_expenses] = :set_expenses
    paths[:tasks][:delete_expenses] = :remove_expenses
    paths[:tasks][:set_accepted] = :modify_accepted
    paths[:tasks][:delete_accepted] = :modify_accepted
    paths[:tasks][:set_resolver] = :modify_resolver
    paths[:tasks][:delete_resolver] = :modify_resolver
    paths[:tasks][:budgets] = :show_budgets
    paths[:tasks][:set_budgets] = :modify_budgets
    paths[:tasks][:orders] = :show_budgets
    paths[:tasks][:handle_review_request] = :can_request_review
    paths[:tasks][:show] = :show_issues

    #status
    paths[:status] = {}
    paths[:status][:index] = :show_status_page
    paths[:status][:checked] = :mark_alerts_as_checked

    #timelogs
    paths[:timelogs] = {}
    paths[:timelogs][:index] = :show_timelogs
    paths[:timelogs][:create] = :create_timelogs
    paths[:timelogs][:issues_summary] = :get_issues_summary

    #users
    paths[:users] = {}
    paths[:users][:me] = :show_issues
    paths[:users][:index] = :show_issues
    paths[:users][:create] = :create_user
    paths[:users][:destroy] = :deactivate_user
    paths[:users][:add_payment] = :create_transactions
    paths[:users][:salary_checkin] = :correct_balance_salary_check
    paths[:users][:set_role] = :is_admin
    paths[:users][:show] = :show_issues
    paths[:users][:update] = :update_user
    paths[:users][:makeactive] = :activate_user #TODO - rewrite method
    paths[:users][:correction] = :correct_balance_salary_check

    #teams
    paths[:teams] = {}
    paths[:teams][:index] = :show_issues
    paths[:teams][:show] = :show_issues
    paths[:teams][:create] = :create_team
    paths[:teams][:destroy] = :deactivate_team
    paths[:teams][:update] = :create_team
    paths[:teams][:makeactive] = :activate_team
    
    # roles
    paths[:tocat_roles] = {}
    paths[:tocat_roles][:index] = :is_admin
    paths[:tocat_roles][:create] = :is_admin
    paths[:tocat_roles][:new] = :is_admin
    paths[:tocat_roles][:show] = :is_admin
    paths[:tocat_roles][:update] = :is_admin
    paths[:tocat_roles][:update] = :is_admin
    paths[:tocat_roles][:destroy] = :is_admin

    #balance transfers
    paths[:balance_transfers] = {}
    paths[:balance_transfers][:index] = :view_transfers
    paths[:balance_transfers][:create] = :create_transfer
    paths[:balance_transfers][:show] = :view_transfers

    #transfer requests
    paths[:transfer_requests] = {}
    paths[:transfer_requests][:index] = :view_transfers
    paths[:transfer_requests][:create] = :create_transfer
    paths[:transfer_requests][:pay] = :create_transfer
    paths[:transfer_requests][:show] = :view_transfers
    paths[:transfer_requests][:destroy] = :create_transfer
    paths[:transfer_requests][:withdraw] = :create_transfer

    #payment requests
    paths[:payment_requests] = {}
    paths[:payment_requests][:index] = :view_payment_requests
    #paths[:payment_requests][:create] = :create_transfer
    paths[:payment_requests][:create] = :create_payment_request
    paths[:payment_requests][:cancel] = :cancel_payment_request
    paths[:payment_requests][:complete] = :complete_payment_request
    paths[:payment_requests][:dispatch_my] = :dispatch_payment_request
    paths[:payment_requests][:show] = :view_payment_requests
    paths[:payment_requests][:update] = :edit_payment_request

    #transactions
    paths[:transactions] = {}
    paths[:transactions][:index] = :show_issues #TODO FIXME - for balance chart we should have another method there
    paths[:transactions][:show] = :show_transactions
    return true if request[:controller] == 'acl' && request[:action] == 'acl'
    return false unless paths[request[:controller].to_sym].present?
    return false unless paths[request[:controller].to_sym][request[:action].to_sym].present?
    return false unless User.current_user.tocat_allowed_to?(paths[request[:controller].to_sym][request[:action].to_sym])
    true
  end

  def self.permissions #load from config?
    data = {}
    data[:orders] = [:create_orders, :show_orders, :edit_orders, :destroy_orders, :complete_orders, :set_internal_orders, :remove_internal_orders, :show_commission, :update_commission, :set_reseller_orders, :unset_reseller_orders, :delete_task]
    data[:accounts] = [:create_account, :edit_account, :view_linked_accounts, :view_all_accounts]
    data[:invoices] = [:create_invoices, :show_invoices, :destroy_invoices, :paid_invoices]
    data[:issues] = [:modify_accepted, :modify_resolver, :modify_budgets, :show_budgets, :show_issues, :show_aggregated_info, :can_request_review, :can_review_task, :set_expenses, :remove_expenses]
    data[:transactions] = [:show_transactions, :create_transactions]
    data[:dashboard] = [:show_tocat_page, :has_protected_page, :can_see_public_pages, :is_admin, :show_status_page, :mark_alerts_as_checked, :show_activity_feed]
    data[:users] = [:create_user, :update_user, :activate_user, :deactivate_user, :correct_balance_salary_check]
    data[:teams] = [:create_team, :update_team, :activate_team, :deactivate_team]
    data[:internal_payments] = [:view_transfers, :create_transfer,:view_all_transfers]
    data[:external_payments] = [:create_payment_request, :edit_payment_request, :cancel_payment_request, :approve_payment_request, :reject_payment_request, :complete_payment_request, :dispatch_payment_request, :view_payment_requests, :correct_balance_salary_check, :pay_in_cash_bank, :view_all_payment_requests]
    data[:timelogs] = [:show_timelogs, :create_timelogs, :get_issues_summary]

    return data
  end

  def permissions=(perms)
    perms = perms.collect {|p| p.to_sym unless p.blank? }.compact.uniq if perms
    write_attribute(:permissions, perms)
  end

  def add_permission!(*perms)
    self.permissions = [] unless permissions.is_a?(Array)

    permissions_will_change!
    perms.each do |p|
      p = p.to_sym
      permissions << p unless permissions.include?(p)
    end
    save!
  end

  def remove_permission!(*perms)
    return unless permissions.is_a?(Array)
    permissions_will_change!
    perms.each { |p| permissions.delete(p.to_sym) }
    save!
  end

  def has_permission?(perm)
    !permissions.nil? && permissions.include?(perm.to_sym)
  end


  def allowed_to?(action)
    allowed_permissions.include? action.to_sym
  end

  private

  def allowed_permissions
    @allowed_permissions ||= permissions
  end
end
