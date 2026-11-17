module Tools
  class MutationTool < BaseTool
    class << self
      def arguments_schema = ArgumentSchema.call(input_arguments)

      def inherited(subclass)
        super
        subclass.annotations(destructive_hint: true, idempotent_hint: false, open_world_hint: true, read_only_hint: false)
      end

      def operation_type = 'mutation'
      def root_type = Types::MutationType
      def selection_depth = 2
      def variables(arguments) = { 'input' => super }

      private

      def input_arguments
        field.arguments.fetch('input').type.unwrap.arguments.values.reject { |argument| argument.graphql_name == 'clientMutationId' }
      end
    end
  end
end
