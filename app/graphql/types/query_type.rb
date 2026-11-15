module Types
  class QueryType < Types::BaseObject
    description 'GraphQL Queries'

    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    {
      bill: PaymentTransaction,
      broker_carrier: BrokerCarrier,
      broker_customer: BrokerCustomer,
      carrier: Carrier,
      customer: Customer,
      invoice: Receivable,
      shipment: Shipment
    }.each do |name, model|
      field name, "Types::#{name.to_s.camelize}Type".constantize, authorize: { to: :view? }, null: true do
        argument :id, ID, required: true
      end

      define_method(name) { |id:| model.find_by(id:) }

      field name.to_s.pluralize.to_sym, resolver: "Resolvers::#{name.to_s.camelize.pluralize}Resolver".constantize
    end

    def shipment(id:) = Shipment.find_by(load_id: id)
  end
end
