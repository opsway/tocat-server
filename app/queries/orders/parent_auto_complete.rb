module Queries
  module Orders
    module ParentAutoComplete
      def self.call(child_id:, term:, limit: 10)
        child = Order.find_by(id: child_id)
        orders = Order.where.not(id: child_id)
                   .where('id LIKE ? OR name LIKE ?', "%#{term}%", "%#{term}%")
                   .limit(limit)
        orders = orders.where('free_budget >= ?', child.invoiced_budget) if child
        orders
      end
    end
  end
end
