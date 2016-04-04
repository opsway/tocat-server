module Queries
  module Invoices
    class Index < Queries::Common::Index
      def initialize(relation: Invoice.unscoped)
        super(relation: relation)
      end

      private

      def sorter
        Invoices::Sorter.new(relation: relation)
      end
    end
  end
end
