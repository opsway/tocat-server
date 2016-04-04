module Queries
  module Invoices
    module Sorters
      class Total < Queries::Common::Sorters::Base
        def call(order:)
          subquery = invoice_sum_subquery.to_sql
          self.relation = relation.select('invoices.*', 'COALESCE(o.invoice_sum, 0) as invoice_sum')
                            .joins("LEFT JOIN (#{subquery}) as o on o.invoice_id = invoices.id")
                            .order("COALESCE(o.invoice_sum, 0) #{direction(order)}")
          self
        end

        private

        def invoice_sum_subquery
          Order.select('SUM(invoiced_budget) as invoice_sum, invoice_id')
            .group(:invoice_id)
        end
      end
    end
  end
end
