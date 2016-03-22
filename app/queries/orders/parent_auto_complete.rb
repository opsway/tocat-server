module Queries
  module Orders
    module ParentAutoComplete
      def self.call(child_id:, term: nil, limit: 10)
        child = Order.find_by(id: child_id)
        orders = Order.where.not(id: child_id)
                   .where(completed: false)
                   .where(parent_id: nil)
                   .order(name: :asc)
                   .limit(limit)
        unless term.blank?
          orders = orders.where('id LIKE ? OR name LIKE ?', "%#{term}%", "%#{term}%")
        end

        if child
          orders = orders.where('free_budget >= ?', child.invoiced_budget)
                         .where.not(team_id: child.team_id)
        end
        orders
      end
    end
  end
end
