module Types
  class TaskType < Types::BaseObjectWithTimestamp
    class << self
      def policy_class = ProblemPolicy
    end

    description 'GraphQL Object for Tasks the broker resolves on a shipment'

    field :assigned_to, Types::UserType, null: false
    field :body, String
    field :code, String, method: :problematic_rule_code, null: false
    field :id, ID, null: false
    field :resolved, Boolean, method: :resolved?, null: false
    field :resolved_at, GraphQL::Types::ISO8601DateTime
    field :resolved_by, Types::UserType
    field :shipment, Types::ShipmentType, authorize: { raise: false, to: :view? }
    field :title, String

    def assigned_to = dataloader.with(Sources::Association, Problem, :assigned_to).load(object)
    def resolved_by = dataloader.with(Sources::Association, Problem, :resolved_by).load(object)

    def shipment
      resolvable = dataloader.with(Sources::Association, Problem, :resolvable).load(object)

      resolvable if resolvable.is_a?(Shipment)
    end
  end
end
