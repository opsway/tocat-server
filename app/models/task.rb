class Task < ActiveRecord::Base
  validates :external_id,  presence: { message: "Missing external task ID" }
  validate :check_resolver_team, if: Proc.new { |o| o.user_id_changed? && !o.user_id.nil?}
  validates_associated :task_orders

  has_many :task_orders, class_name: 'TaskOrders', :autosave => true

  has_many :orders, through: :task_orders, :autosave => true

  before_save :handle_balance_after_changing_resolver, if: Proc.new { |o| o.paid && o.user_id_changed? }
  before_save :handle_balance_after_changing_paid_status, if: Proc.new { |o| o.paid_changed? && user_id.present? }

  belongs_to :user

  accepts_nested_attributes_for :task_orders, reject_if: :all_blank, allow_destroy: true

  filterrific(
    default_filter_params: { sorted_by: 'created_at_asc' },
    available_filters: [
      :sorted_by,
      :search_query,
      :paid
    ]
  )

  scope :search_query, lambda { |query|
      # see http://filterrific.clearcove.ca/pages/active_record_scope_patterns.html
      # for details
    return nil  if query.blank?
    terms = query.to_s.downcase.split(/\s+/)
    terms = terms.map { |e|
      (e.gsub('*', '%') + '%').gsub(/%+/, '%')
    }
    num_or_conds = 1
    where(
      terms.map { |term|
        "LOWER(tasks.external_id) LIKE ?"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  scope :paid, lambda { |flag|
    where(paid: ActiveRecord::Type::Boolean.new.type_cast_from_user(flag))
  }

  scope :sorted_by, lambda { |sort_option|
    if sort_option.split(',').count > 1
      sort_option.gsub!(/\s/, '')
      order_params = []
      sort_option.split(',').each do |option|
        direction = (option =~ /desc$/) ? 'desc' : 'asc'
        case option.to_s
        when /^external_id_/
          order_params << "LOWER(tasks.external_id) #{ direction }"
        when /^budget_/
          order_params << "tasks.budget #{ direction }"
        else
          raise(ArgumentError, "Invalid sort option: #{ option.inspect }")
        end
      end
      order(order_params.join(', '))
    else
      direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
      case sort_option.to_s
      when /^external_id_/
        order("LOWER(tasks.external_id) #{ direction }")
      when /^budget_/
        order("tasks.budget #{ direction }")
      else
        raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
      end
    end

  }

  def can_be_paid?
    can_be_paid = true
    orders.each do |order|
      can_be_paid = order.paid unless order.paid
    end
    can_be_paid
  end

  def handle_paid(paid)
    if paid
      if can_be_paid?
        return self.update_attributes(paid: true)
      else
        return false
      end
    else
      return self.update_attributes(paid: false)
    end
  end

  def team
    team = nil
    if task_orders.present?
      task_orders.reload.each { |o| team = o.order.team if team != o.order.team}
    end
    team
  end

  def resolver
    self.user
  end

  def budget
    budget = BigDecimal 0
    task_orders.each do |record|
      budget += record.budget
    end
    budget
  end

  def external_url
    #Settings.external_tracker.url + external_id
  end

  private

  def validate_nested_attributes
    task_orders.each do |record|
      unless record.task.present?
        errors[:base] << ""
      end
      unless task.team == order.team
        errors[:base] << "Orders are created for different teams"
      end
    end
  end

  def handle_balance_after_changing_paid_status
    if paid
      user.balance_account.transactions.create! total: budget,
                                               comment: "#{self.id} accepted and paid",
                                               user_id: 0
      user.team.balance_account.transactions.create! total: budget,
                                               comment: "#{self.id} accepted and paid",
                                               user_id: 0
    else
      user.balance_account.transactions.create! total: - budget,
                                               comment: "#{self.id} unaccepted and unpaid",
                                               user_id: 0
      user.team.balance_account.transactions.create! total: - budget,
                                               comment: "#{self.id} unaccepted and unpaid",
                                               user_id: 0
    end
  end

  def handle_balance_after_changing_resolver
    if user_id_was != nil
      old_user = User.find(user_id_was)
      old_user.balance_account.transactions.create! total: - budget,
                                                    comment: "User was removed from #{id} task",
                                                    user_id: 0
      old_user.team.balance_account.transactions.create! total: - budget,
                                                         comment: "User #{old_user.login} was removed from #{id} task",
                                                         user_id: 0
    end
    if user_id != nil
      user.balance_account.transactions.create! total: budget,
                                               comment: "User was setted as resolver for #{id} task",
                                               user_id: 0
      user.team.balance_account.transactions.create! total: budget,
                                               comment: "User #{user.login} was setted as resolver for #{id} task",
                                               user_id: 0
    end
  end

  def check_resolver_team
    return true if orders.first.nil?
    team = orders.first.team
    orders.each do |order|
      if team != order.team
        errors[:base] << "Task resolver is from different team than order"
      end
    end
    if user.team != team
      errors[:base] << "Task resolver is from different team than order"
    end
  end
end
