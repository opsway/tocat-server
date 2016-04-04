module Queries
  module Common
    module Sorters
      class Base
        VALID_ORDERS = %w(asc desc)

        attr_reader :relation, :column

        def initialize(relation:, column:)
          @relation = relation
          @column = column
        end

        def call(order:)
          self
        end

        private

        attr_writer :relation

        def direction(order)
          return order if valid_order?(order)
          default_order
        end

        def valid_order?(order)
          VALID_ORDERS.include?(order)
        end

        def default_order
          'asc'
        end
      end
    end
  end
end