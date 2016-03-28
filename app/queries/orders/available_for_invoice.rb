module Queries
  module Orders
    module AvailableForInvoice
      def self.call(limit: 1000)
        Order.where(
          invoice: nil,
          internal_order: false,
          paid: false,
          parent: nil
        ).order(name: :asc)
          .limit(limit)
      end
    end
  end
end
