module Actions
  module Tasks
    class SetBudgets < Actions::BaseAction
      attr_reader :task

      def initialize(task)
        super()
        @task = task
      end

      def call(budgets:)
        prepared_budgets = prepare_budgets(budgets)

        push_operation(-> { check_requirements })
        push_operation(-> { remember_previous_budgets })
        push_operation(-> { set_budgets(prepared_budgets) })
        push_operation(-> { task.recalculate_paid_status! }) # FIXME
        push_operation(-> { create_activity })

        execute_operations

        self
      end

      private

      attr_reader :previous_budgets

      def prepare_budgets(budgets)
        {
          task_orders_attributes: (budgets || [])
        }
      end

      def set_budgets(budgets)
        task.task_orders.destroy_all
        task.update(budgets)
        task_orders_errors = task.task_orders.flat_map { |to| to.errors.full_messages }
        task.reload
        push_errors(task_orders_errors)
      end

      def check_requirements
        #push_errors(I18n.t('errors.task.budget.cant_update_when_expense')) if task.expenses?
        push_errors(I18n.t('errors.task.budget.cant_update_when_accepted_and_paid')) if task.accepted? && task.paid?
      end

      def remember_previous_budgets
        @previous_budgets ||= serialized_task_budgets
      end

      def create_activity
        task.create_activity(
          :budget_update,
          parameters: {
            old: previous_budgets,
            new: serialized_task_budgets
          },
          owner: User.current_user)
      end

      def serialized_task_budgets
        task.task_orders.each(&:serializable_hash)
      end
    end
  end
end
