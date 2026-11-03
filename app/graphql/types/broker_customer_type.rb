module Types
  class BrokerCustomerType < Types::BaseObject
    description 'GraphQL Object for Broker Customer Model'

    field :accounting_customer_id, String
    field :always_show_quotes_based_on_calculated_classes, Boolean
    field :broker_carriers, Types::BrokerCarrierCollectionType, null: false, resolver: Resolvers::BrokerCarriersResolver
    field :can_quote, Boolean
    field :customer, Types::CustomerType, authorize: { raise: false, to: :view? }
    field :default_bol_notes, String
    field :default_upcharge_cents, Integer, visible_to: :view_markup?
    field :default_upcharge_currency, String, visible_to: :view_markup?
    field :default_upcharge_percentage, Float, visible_to: :view_markup?
    field :enable_auto_freight_class, Boolean
    field :id, ID, null: false
    field :ignore_value_on_api_quotes, Boolean
    field :internal_notes, String, visible_to: :view_internal_notes?
    field :office_address, Types::AddressType, null: false
    field :preferred_broker_carriers_kind, String
    field :primary_pickup_address, Types::AddressType, null: false
    field :receivables_contact_id, Integer, null: false
    field :receivables_schedule, String
    field :requires_carrier_bol_on_receivables, Boolean
    field :requires_carrier_pod_on_receivables, Boolean
    field :requires_charges_confirmed_on_receivables, Boolean
    field :requires_customer_reference_number_on_receivables, Boolean
    field :requires_shipment_delivery_before_receivable, Boolean
    field :requires_shipment_shipper_reference_on_receivables, Boolean
    field :shipment_string_patterns, String
    field :shipments, Types::ShipmentCollectionType, null: false, resolver: Resolvers::ShipmentsResolver
    field :valid_freight_classes, String

    def customer = dataloader.with(Sources::Association, BrokerCustomer, :customer).load(object)
    def office_address = dataloader.with(Sources::Association, BrokerCustomer, :office_address).load(object)
    def primary_pickup_address = dataloader.with(Sources::Association, BrokerCustomer, :primary_pickup_address).load(object)
  end
end
