module Actions
  module Orders
    class Base < Actions::BaseAction
      attr_reader :order

      def initialize(order)
        super()
        @order = order
      end

      private

      def order_errors
        self.order.errors.messages.values.flatten
      end
    end
  end
end
