module Types
  class ShipmentType < Types::BaseObjectWithTimestamp
    description 'GraphQL Object for Shipment Model'

    field :broker, Types::BrokerType
    field :broker_carrier, Types::BrokerCarrierType
    field :customer_reference, String
    field :id, ID, null: false
    field :picked_up, Boolean
    field :pickup_confirmation, String
    field :priority, Integer
    field :pro, String
    field :shipper_name, String
    field :shipper_reference, String

    field :bol, String
    field :lift_gate_delivery, Boolean
    field :lift_gate_pickup, Boolean
    field :notify, Boolean
    field :receiver_address_id, Integer
    field :receiver_contact_email, String
    field :receiver_contact_name, String
    field :receiver_contact_phone, String
    field :receiver_name, String
    field :shipper_address_id, Integer
    field :shipper_bol, String
    field :shipper_contact_email, String
    field :shipper_contact_name, String
    field :shipper_contact_phone, String

    field :booked_at, GraphQL::Types::ISO8601DateTime
    field :canceled_at, GraphQL::Types::ISO8601DateTime
    field :delivered_at, GraphQL::Types::ISO8601DateTime
    field :delivery_appointment_at, GraphQL::Types::ISO8601DateTime
    field :delivery_appointment_on, GraphQL::Types::ISO8601Date
    field :delivery_eta_on, GraphQL::Types::ISO8601Date
    field :departed_origin_terminal_at, GraphQL::Types::ISO8601DateTime
    field :dispatched_at, GraphQL::Types::ISO8601DateTime
    field :lost_on, GraphQL::Types::ISO8601Date
    field :out_for_delivery_at, GraphQL::Types::ISO8601DateTime
    field :pending_appointment_since, GraphQL::Types::ISO8601Date
    field :picked_up_at, GraphQL::Types::ISO8601DateTime
    field :pickup_driver_assigned_at, GraphQL::Types::ISO8601DateTime
    field :pickup_on, GraphQL::Types::ISO8601Date
    field :promised_delivery_by, GraphQL::Types::ISO8601DateTime
    field :quoted_delivery_by, GraphQL::Types::ISO8601DateTime
    field :receiver_available_at, GraphQL::Types::ISO8601DateTime
    field :receiver_unavailable_at, GraphQL::Types::ISO8601DateTime
    field :shipper_available_at, GraphQL::Types::ISO8601DateTime
    field :shipper_unavailable_at, GraphQL::Types::ISO8601DateTime

    field :quote_id, String
    field :total_charges_cents, Integer, null: false
    field :total_charges_currency, String, null: false
    field :total_cost_cents, Integer, null: false
    field :total_cost_currency, String, null: false

    field :bol_notes, String
    field :broker_customer_id, Integer
    field :broker_notes, String
    field :carrier_charge_cents, Integer, null: false
    field :carrier_charge_currency, String, null: false
    field :carrier_cost_cents, Integer, null: false
    field :carrier_cost_currency, String, null: false
    field :customer_notes, String
    field :load_id, Integer
    field :updated_by_id, Integer
    field :value_cents, Integer, null: false
    field :value_currency, String, null: false

    field :truckload, Boolean

    field :applied_rate_id, Integer
    field :delivery_hours_end_at, String
    field :delivery_hours_start_at, String
    field :pickup_eta_at, String
    field :pickup_hours_end_at, String
    field :pickup_hours_start_at, String
    field :tracking_carrier_id, Integer
    field :tracking_carrier_pickup_confirmation, String
    field :tracking_carrier_pro, String

    field :quote_only, Boolean

    field :broker_and_broker_customer_notes, String
    field :broker_bol_shipment_fingerprint, String
    field :broker_dispatch_sheet_shipment_fingerprint, String
    field :broker_quote_shipment_fingerprint, String
    field :charges_confirmed, Boolean
    field :created_by_id, Integer
    field :dispatcher_id, Integer
    field :public_notes, String
    field :status, String
  end
end
