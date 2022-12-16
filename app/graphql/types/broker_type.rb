# frozen_string_literal: true

module Types
  class BrokerType < Types::BaseObject
    field :id, ID, null: false
    field :name, String
    field :phone, String
    field :customer_service_email, String
    field :first_load_id, Integer
    field :default_bol_notes, String
    field :robot_email, String
    field :time_zone_name, String, null: false
    field :uuid, String, null: false
    field :automatically_authorize_receivables, Boolean
    field :automatically_update_shipment_tracking_based_on_carrier_apis, Boolean
    field :ignore_broker_carrier_bol_requires_tracking_number, Boolean
    field :requires_charges_confirmed_on_receivables, Boolean
  end
end
