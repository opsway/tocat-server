module Queries
  module Common
    module Sorters
      class Column < Base
        def call(order:)
          self.relation = relation.order("#{column} #{direction(order)}")
          self
        end
      end
    end
  end
end
