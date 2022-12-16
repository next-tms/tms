# frozen_string_literal: true

module Types
  class BrokerCustomerType < Types::BaseObject
    field :id, ID, null: false
    field :customer, Types::CustomerType
    field :broker, Types::BrokerType
    field :shipment_string_patterns, String
    field :default_bol_notes, String
    field :can_quote, Boolean
    field :default_upcharge_cents, Integer, null: false
    field :default_upcharge_currency, String, null: false
    field :default_upcharge_percentage, Float
    field :always_show_quotes_based_on_calculated_classes, Boolean
    field :primary_pickup_address_id, Integer, null: false
    field :valid_freight_classes, String
    field :enable_auto_freight_class, Boolean
    field :internal_notes, String
    field :requires_carrier_bol_on_receivables, Boolean
    field :requires_carrier_pod_on_receivables, Boolean
    field :ignore_value_on_api_quotes, Boolean
    field :office_address_id, Integer, null: false
    field :quickbooks_customer_id, String
    field :receivables_contact_id, Integer, null: false
    field :receivables_schedule, String
    field :requires_shipment_delivery_before_receivable, Boolean
    field :preferred_broker_carriers_kind, String
    field :requires_charges_confirmed_on_receivables, Boolean
    field :requires_customer_reference_number_on_receivables, Boolean
    field :requires_shipment_shipper_reference_on_receivables, Boolean
  end
end
