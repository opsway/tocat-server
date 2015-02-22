class Transaction < ActiveRecord::Base
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :total,
            numericality: true,
            presence: true

  belongs_to :user
  belongs_to :account


  filterrific(
    default_filter_params: { sorted_by: 'created_at_asc' },
    available_filters: [
      :sorted_by,
      :search_query,
      :team,
      :user
    ]
  )
  scope :user, lambda { |id|
    ids = []
    Account.with_accountable(id, 'user').each do |account|
      ids << account.id
    end
    with_account_ids(ids)
  }

  scope :team, lambda { |id|
    ids = []
    Account.with_accountable(id, 'team').each do |account|
      ids << account.id
    end
    with_account_ids(ids)
  }

  scope :with_account_ids, -> (account_ids) { Transaction.where(account_id: [*account_ids]) }

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
        "LOWER(transactions.comment) LIKE ?"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  scope :sorted_by, lambda { |sort_option|
    if sort_option.split(',').count > 1
      sort_option.gsub!(/\s/, '')
      order_params = []
      sort_option.split(',').each do |option|
        direction = (option =~ /desc$/) ? 'desc' : 'asc'
        case option.to_s
        when /^total_/
          order_params << "trsansactions.total #{ direction }"
        when /^created_at_/
          order_params << "transactions.created_at #{ direction }"
        else
          raise(ArgumentError, "Invalid sort option: #{ option.inspect }")
        end
      end
      order(order_params.join(', '))
    else
      direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
      case sort_option.to_s
      when /^total_/
        order("trsansactions.total #{ direction }")
      when /^created_at_/
        order("transactions.created_at #{ direction }")
      else
        raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
      end
    end

  }


end
