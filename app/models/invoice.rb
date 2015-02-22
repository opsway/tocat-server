class Invoice < ActiveRecord::Base
  validates_presence_of :external_id
  has_many :orders

  before_destroy :check_if_invoice_used
  before_save :handle_paid_status, if: Proc.new { |o| o.paid_changed? }

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
    num_or_conds = 2
    where(
      terms.map { |term|
        "(LOWER(invoices.external_id) LIKE ? OR LOWER(invoices.client) LIKE ?)"
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
        when /^comment/
          order_params << "invoices.external_id #{ direction }"
        when /^client/
          order_params << "invoices.client #{ direction }"
        else
          raise(ArgumentError, "Invalid sort option: #{ option.inspect }")
        end
      end
      order(order_params.join(', '))
    else
      direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
      case sort_option.to_s
      when /^comment/
        order("invoices.external_id #{ direction }")
      when /^client/
        order("invoices.client #{ direction }")
      else
        raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
      end
    end

  }

  private

  def handle_paid_status
    self.transaction do
      orders.each do |order|
        order.tasks.each {|task| task.handle_paid(paid)}
        raise ActiveRecord::Rollback unless order.handle_paid(paid)
        order.sub_orders.each do |sub_order|
          sub_order.tasks.each {|task| task.handle_paid(paid)}
          raise ActiveRecord::Rollback unless sub_order.handle_paid(paid)
        end
      end
    end
  end

  def check_if_invoice_used
    if orders.present?
      errors[:base] << 'Invoice is linked to orders'
      false
    end
  end
end
