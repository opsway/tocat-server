module Actions
  module Orders
    class Update < Actions::BaseAction
      attr_reader :order

      def initialize(order)
        super()
        @order = order
      end

      def call(order_params:)
        parent_id = order_params.delete(:parent_id)

        push_operation(-> { update_order(order_params) })
        push_operation(-> { set_parent(parent_id) })
        push_operation(-> { save_order })
        push_operation(-> { create_activity })

        execute_operations
        self
      end

      private

      attr_accessor :order_changes

      def update_order(order_params)
        remember_changes(order_params)
        order.assign_attributes(order_params)
      end

      def save_order
        self.order.save
        push_errors(order_errors)
      end

      def set_parent(parent_id)
        action = Actions::Orders::SetParent.new(order).call(parent_id: parent_id)
        push_errors(action.errors)
      end

      def order_errors
        self.order.errors.messages.values.flatten
      end

      def create_activity
        order.create_activity(
          :update,
          parameters: { changes: order_changes },
          owner: User.current_user
        )
      end

      def remember_changes(params)
        @order_changes ||= HashDiff.diff(original_order_data, params)
      end

      def original_order_data
        {
          'name' => order.name,
          'description' => order.description,
          'invoiced_budget' => order.invoiced_budget.to_s,
          'allocatable_budget' => order.allocatable_budget.to_s,
          'team_id' => order.team_id.to_s,
          'parent_id' => order.parent_id
        }
      end
    end
  end
end
