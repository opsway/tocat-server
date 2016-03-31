module Actions
  class BaseAction
    attr_reader :errors

    def initialize
      @errors = []
      @operations = []
    end

    def success?
      errors.empty?
    end

    def failure?
      !success?
    end

    def call
    end

    private

    attr_accessor :operations

    def push_operation(operation)
      @operations << operation
    end

    def execute_operations
      ActiveRecord::Base.transaction do
        operations.each do |operation|
          operation.call
          break if failure?
        end
        fail(ActiveRecord::Rollback, 'Rolling back') if failure?
      end
    end

    def push_errors(errors_messages)
      @errors += Array(errors_messages)
    end
  end
end
