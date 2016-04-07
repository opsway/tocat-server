module Queries
  module Common
    class Index
      attr_reader :relation

      def initialize(relation:)
        @relation = relation
      end

      def call
        self
      end

      def search(params)
        self.relation = relation.search_for(params)
        self
      end

      def sort(params)
        self.relation = sorter.call(params).relation
        self
      end

      private

      attr_writer :relation

      def sorter
        Invoices::Sorter.new(relation: relation)
      end
    end
  end
end
