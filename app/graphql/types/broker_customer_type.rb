# frozen_string_literal: true

module Types
  class BrokerCustomerType < Types::BaseObject
    description 'GraphQL Object for Broker Customer Model'

    field :always_show_quotes_based_on_calculated_classes, Boolean
    field :broker, Types::BrokerType
    field :can_quote, Boolean
    field :customer, Types::CustomerType
    field :default_bol_notes, String
    field :default_upcharge_cents, Integer, null: false
    field :default_upcharge_currency, String, null: false
    field :default_upcharge_percentage, Float
    field :enable_auto_freight_class, Boolean
    field :id, ID, null: false
    field :ignore_value_on_api_quotes, Boolean
    field :internal_notes, String
    field :office_address_id, Integer, null: false
    field :preferred_broker_carriers_kind, String
    field :primary_pickup_address_id, Integer, null: false
    field :quickbooks_customer_id, String
    field :receivables_contact_id, Integer, null: false
    field :receivables_schedule, String
    field :requires_carrier_bol_on_receivables, Boolean
    field :requires_carrier_pod_on_receivables, Boolean
    field :requires_charges_confirmed_on_receivables, Boolean
    field :requires_customer_reference_number_on_receivables, Boolean
    field :requires_shipment_delivery_before_receivable, Boolean
    field :requires_shipment_shipper_reference_on_receivables, Boolean
    field :shipment_string_patterns, String
    field :valid_freight_classes, String
  end
end
