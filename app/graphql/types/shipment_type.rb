module Types
  class ShipmentType < Types::BaseObjectWithTimestamp
    description 'GraphQL Object for Shipment Model'

    field :applied_rate_id, Integer
    field :bol, String
    field :bol_notes, String
    field :booked_at, GraphQL::Types::ISO8601DateTime
    field :broker_and_broker_customer_notes, String, visible_to: :view_shared_notes?
    field :broker_notes, String, visible_to: :view_internal_notes?
    field :canceled_at, GraphQL::Types::ISO8601DateTime
    field :carrier, Types::CarrierType, authorize: { raise: false, to: :view? }
    field :carrier_account, Types::CarrierAccountType, authorize: { raise: false, to: :view? }
    field :carrier_charge_cents, Integer, visible_to: :view_charges?
    field :carrier_charge_currency, String, visible_to: :view_charges?
    field :carrier_cost_cents, Integer, visible_to: :view_costs?
    field :carrier_cost_currency, String, visible_to: :view_costs?
    field :charges_confirmed, Boolean
    field :created_by_id, Integer
    field :customer, Types::CustomerType, authorize: { raise: false, to: :view? }
    field :customer_notes, String
    field :customer_reference, String
    field :delivered_at, GraphQL::Types::ISO8601DateTime
    field :delivery_appointment_at, GraphQL::Types::ISO8601DateTime
    field :delivery_appointment_on, GraphQL::Types::ISO8601Date
    field :delivery_eta_on, GraphQL::Types::ISO8601Date
    field :delivery_hours_end_at, String
    field :delivery_hours_start_at, String
    field :departed_origin_terminal_at, GraphQL::Types::ISO8601DateTime
    field :dispatched_at, GraphQL::Types::ISO8601DateTime
    field :dispatcher_id, Integer
    field :documents, [Types::DocumentType], null: false
    field :events, [Types::TrackingEventType], null: false
    field :id, ID, method: :load_id, null: false
    field :items, [Types::ItemType], null: false
    field :lift_gate_delivery, Boolean
    field :lift_gate_pickup, Boolean
    field :load_id, Integer
    field :lost_on, GraphQL::Types::ISO8601Date
    field :notify, Boolean
    field :out_for_delivery_at, GraphQL::Types::ISO8601DateTime
    field :pending_appointment_since, GraphQL::Types::ISO8601Date
    field :picked_up, Boolean, method: :picked_up?
    field :picked_up_at, GraphQL::Types::ISO8601DateTime
    field :pickup_confirmation, String, visible_to: :view_carrier_references?
    field :pickup_driver_assigned_at, GraphQL::Types::ISO8601DateTime
    field :pickup_eta_at, String
    field :pickup_hours_end_at, String
    field :pickup_hours_start_at, String
    field :pickup_on, GraphQL::Types::ISO8601Date
    field :priority, Integer
    field :pro, String, null: true
    field :promised_delivery_by, GraphQL::Types::ISO8601DateTime
    field :public_notes, String
    field :quote_id, String
    field :quote_only, Boolean
    field :quoted_delivery_by, GraphQL::Types::ISO8601DateTime
    field :receiver_address, Types::AddressType, null: false
    field :receiver_available_at, GraphQL::Types::ISO8601DateTime
    field :receiver_contact_email, String
    field :receiver_contact_name, String
    field :receiver_contact_phone, String
    field :receiver_name, String, method: :receiver_address_name
    field :receiver_unavailable_at, GraphQL::Types::ISO8601DateTime
    field :shipper_address, Types::AddressType, null: false
    field :shipper_available_at, GraphQL::Types::ISO8601DateTime
    field :shipper_bol, String
    field :shipper_contact_email, String
    field :shipper_contact_name, String
    field :shipper_contact_phone, String
    field :shipper_name, String, method: :shipper_address_name
    field :shipper_reference, String
    field :shipper_unavailable_at, GraphQL::Types::ISO8601DateTime
    field :status, Types::ShipmentStatusEnum
    field :total_charges_cents, Integer, visible_to: :view_charges?
    field :total_charges_currency, String, visible_to: :view_charges?
    field :total_cost_cents, Integer, visible_to: :view_costs?
    field :total_cost_currency, String, visible_to: :view_costs?
    field :tracking_carrier_id, Integer
    field :tracking_carrier_pickup_confirmation, String, visible_to: :view_carrier_references?
    field :tracking_carrier_pro, String, visible_to: :view_carrier_references?
    field :truckload, Boolean
    field :updated_by_id, Integer
    field :value_cents, Integer, null: false
    field :value_currency, String, null: false

    def carrier
      carrier_account&.then { |broker_carrier| dataloader.with(Sources::Association, BrokerCarrier, :carrier).load(broker_carrier) }
    end

    def carrier_account = dataloader.with(Sources::Association, Shipment, :broker_carrier).load(object)
    def customer = dataloader.with(Sources::Association, Shipment, :broker_customer).load(object)

    def documents
      shipment_attachments = dataloader.with(Sources::Association, Shipment, :document_attachments).request(object)
      receivables = dataloader.with(Sources::Association, Shipment, :receivables).load(object)
      invoices = dataloader.with(Sources::Association, Receivable, :invoice_attachment).load_all(receivables).compact
      attachments = shipment_attachments.load + invoices
      dataloader.with(Sources::Association, ActiveStorage::Attachment, :blob).load_all(attachments)

      attachments.select { |attachment| allowed_to?(:view?, attachment, with: DocumentPolicy) }.sort_by(&:created_at)
    end

    def events
      tracking_events = dataloader.with(Sources::Association, Shipment, :tracking_events).load(object)

      tracking_events.select { |tracking_event| allowed_to?(:view?, tracking_event) }.sort_by { |tracking_event| tracking_event.at.to_i }
    end

    def items = dataloader.with(Sources::Association, Shipment, :items).load(object)
    def pro = allowed_to?(:view_carrier_references?, object) ? object.pro : object.customer_pro
    def receiver_address = dataloader.with(Sources::Association, Shipment, :receiver_address).load(object)
    def shipper_address = dataloader.with(Sources::Association, Shipment, :shipper_address).load(object)
  end
end
