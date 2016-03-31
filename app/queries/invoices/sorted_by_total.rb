module Queries
  module Invoices
    class SortedByTotal
      attr_reader :relation

      def initialize(relation: Invoice.unscoped)
        @relation = relation
      end

      def call(order:)
        subquery = invoice_sum_subquery.to_sql
        direction = order_direction(order)
        self.relation = self.relation
          .select('invoices.*', 'COALESCE(o.invoice_sum, 0) as invoice_sum')
          .joins("LEFT JOIN (#{subquery}) as o on o.invoice_id = invoices.id")
          .order("COALESCE(o.invoice_sum, 0) #{direction}")
          .order("id #{direction}")
      end

      private

      attr_writer :relation

      def invoice_sum_subquery
        Order.select('SUM(invoiced_budget) as invoice_sum, invoice_id')
          .group(:invoice_id)
      end

      def order_direction(order)
        return order if order == 'desc'
        'asc'
      end
    end
  end
end
