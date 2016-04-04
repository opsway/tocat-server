module Queries
  module Common
    class Sorter
      FALLBACK_SORTER = Sorters::Column
      DEFAULT_SORTER = Sorters::Column
      SORTERS = {}

      attr_reader :relation

      def initialize(relation:)
        @relation = relation
      end

      def call(params)
        params.split(/\s*,\s*/).each do |option|
          column = column(option)
          direction = (option =~ /desc$/) ? 'desc' : 'asc'
          sorter = sorter_for(column)
          next unless sorter
          self.relation = sorter.call(order: direction).relation
        end
        fallback_sort if params.empty?
        self
      end

      private

      attr_writer :relation

      def column(sort_param)
        sort_param.split(':').first
      end

      def sorter_for(column)
        klass = sorter_class_for(column)
        return unless klass
        klass.new(relation: relation, column: column)
      end

      def sorter_class_for(column)
        sorter = sorters.fetch(column, nil)
        sorter ||= default_sorter_class if column_default_sortable?(column)
        sorter
      end

      def fallback_sort
        self.relation = fallback_sorter.new(relation: relation, column: 'id')
          .call(order: 'desc')
          .relation
      end

      def column_default_sortable?(column)
        relation.column_names.include?(column)
      end

      def default_sorter_class
        self.class::DEFAULT_SORTER
      end

      def sorters
        self.class::SORTERS
      end

      def fallback_sorter
        self.class::FALLBACK_SORTER
      end
    end
  end
end
