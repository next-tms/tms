module Types
  class BrokerType < Types::BaseObject
    description 'GraphQL Object for Broker Model'

    field :automatically_authorize_receivables, Boolean
    field :customer_service_email, String
    field :default_bol_notes, String
    field :first_load_id, Integer
    field :id, ID, null: false
    field :ignore_broker_carrier_bol_requires_tracking_number, Boolean
    field :name, String
    field :phone, String
    field :requires_charges_confirmed_on_receivables, Boolean
    field :robot_email, String
    field :time_zone_name, String, null: false
    field :uuid, String, null: false
  end
end
