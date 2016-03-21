module Actions
  module Orders
    class Complete < Base
      def call
        push_operation(-> { check_requirements })
        push_operation(-> { complete_order })
        push_operation(-> { create_activity })

        execute_operations
        self
      end

      private

      def check_requirements
        order_not_completed
        order_paid
        order_is_not_a_suborder
        tasks_accepted_and_paid
        tasks_have_expenses_or_resolver
      end

      def order_not_completed
        push_errors(I18n.t('errors.order.completed.cant_complete_when_completed')) if order.completed?
      end

      def order_paid
        push_errors(I18n.t('errors.order.completed.cant_complete_when_unpaid')) unless order.paid?
      end

      def order_is_not_a_suborder
        push_errors(I18n.t('errors.order.completed.cant_complete_when_suborder')) if order.parent.present?
      end

      def tasks_accepted_and_paid
        tasks = order.tasks + order.sub_orders.flat_map(&:tasks)
        ids = tasks.reject { |t| t.accepted? && t.paid? }.map(&:external_id)
        push_errors(I18n.t('errors.order.completed.cant_complete_when_tasks_not_accepted_and_paid', ids: ids.join(','))) if ids.any?
      end

      def tasks_have_expenses_or_resolver
        type_1_ids = incorrect_tasks_type_1_ids
        push_errors(I18n.t('errors.order.completed.cant_complete_when_have_incorrect_tasks_type_1', ids: type_1_ids.join(','))) unless type_1_ids.empty?
        type_2_ids = incorrect_tasks_type_2_ids
        push_errors(I18n.t('errors.order.completed.cant_complete_when_have_incorrect_tasks_type_2', ids: type_2_ids.join(','))) unless type_2_ids.empty?
      end

      # when tasks have expenses and resolver set
      def incorrect_tasks_type_1_ids
        order_tasks_ids = order.tasks.with_expenses.with_resolver.pluck(:external_id)
        children_tasks_ids = order.sub_orders.includes(:tasks).flat_map do |sub_order|
          sub_order.tasks
            .select { |t| t.expenses? && t.resolver.present? }
            .map(&:external_id)
        end
        order_tasks_ids + children_tasks_ids
      end

      # when tasks have no expenses no resolver set
      def incorrect_tasks_type_2_ids
        order_tasks_ids = order.tasks.without_expenses.without_resolver.pluck(:external_id)
        children_tasks_ids = order.sub_orders.includes(:tasks).flat_map do |sub_order|
          sub_order.tasks
            .select { |t| !t.expenses? && !t.resolver.present? }
            .map(&:external_id)
        end
        order_tasks_ids + children_tasks_ids
      end

      def complete_order
        order.update_attributes(completed: true)
        push_errors(order_errors)
      end

      def create_activity
        @order.create_activity(
          :completed_update,
          parameters: {
            new: @order.completed?,
            old: !@order.completed?
          },
          owner: User.current_user)
      end
    end
  end
end
