module Queries
  module Invoices
    class Sorter < Queries::Common::Sorter
      SORTERS = {
        'total' => Invoices::Sorters::Total
      }
    end
  end
end
