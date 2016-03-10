module Actions
  module Orders
    class SetParent < Actions::BaseAction
      attr_reader :order

      def initialize(order)
        super()
        @order = order
      end

      def call(parent_id:)
        new_parent = find_parent(parent_id)
        return self if order.parent == new_parent
        remember_prev_parent

        push_operation(-> { check_requirements })
        push_operation(-> { set_parent(new_parent) })
        push_operation(-> { recalculate_budget(new_parent) })
        push_operation(-> { recalculate_budget(prev_parent) })
        push_operation(-> { create_activity(prev_parent, new_parent) })

        execute_operations

        self
      end

      private

      attr_reader :prev_parent

      def set_parent(parent)
        order.parent = parent
        order.save
        push_errors(order_errors)
      end

      def create_activity(prev_parent, new_parent)
        changes = HashDiff.diff(
          { parent_id: prev_parent.try(:id) },
          { parent_id: new_parent.try(:id) })
        order.create_activity(
          :update,
          parameters: { changes: changes },
          owner: User.current_user
        )
      end

      def recalculate_budget(parent)
        parent.recalculate_free_budget! if parent
      end

      def remember_prev_parent
        @prev_parent = order.parent
      end

      def find_parent(parent_id)
        Order.find_by(id: parent_id.to_i)
      end

      def check_requirements
        push_errors(['Order has invoice linked - can not change parent order']) if order.invoice.present?
        push_errors(['Order is set as Internal - can not change parent order']) if order.internal_order?
      end

      def order_errors
        self.order.errors.messages.values.flatten
      end
    end
  end
end
