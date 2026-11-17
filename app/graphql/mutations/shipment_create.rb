module Mutations
  class ShipmentCreate < BaseMutation
    include Mutations::Concerns::Rateable
    include Mutations::Concerns::Shippable

    HOURS = %i[delivery_hours_end_at delivery_hours_start_at pickup_hours_end_at pickup_hours_start_at].freeze
    HOURS_FORMAT = '%-l:%M %p'.freeze
    LANE_ATTRIBUTES = ['city', 'region_iso31662', 'zip_code'].freeze

    argument :bol_notes, String, required: false
    argument :customer_reference, String, required: false
    argument :delivery_hours_end_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :delivery_hours_start_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :pickup_hours_end_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :pickup_hours_start_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :pickup_on, GraphQL::Types::ISO8601Date, required: false
    argument :rate_id, ID, required: true
    argument :receiver, Types::LocationInputObject, required: false
    argument :shipper, Types::LocationInputObject, required: false
    argument :shipper_reference, String, required: false

    field :shipment, Types::ShipmentType, null: false

    def resolve(rate_id:, receiver: nil, shipper: nil, **attributes)
      rate = Rate.find_by(id: rate_id)
      shipment = rate&.shipment

      authorize!(shipment, to: :fetch_rates?, with: ShipmentPolicy)

      shipment.with_lock do
        check_bookable!(shipment, rate)
        save_shipment(shipment, applied_rate_uid: rate.uid, booked_at: Time.current, quote_only: false)

        shipment.assign_attributes(details(shipment, rate, attributes, receiver:, shipper:))
        raise_error('The lane differs from the quote', 'RATE_OUTDATED') if lane_changed?(shipment)

        save_shipment(shipment)
      end

      { shipment: }
    end

    private

    def bookable?(rate) = quotable?(rate) && (rate.expires_at.blank? || rate.expires_at.future?)

    def check_bookable!(shipment, rate)
      raise_error('Customer not found', 'NOT_FOUND') if shipment.broker_customer.blank?
      raise_error('Shipment is already booked', 'BOOKED') if shipment.booked_at.present?
      raise_error('Rate is not bookable', 'UNBOOKABLE_RATE') unless bookable?(rate) && eligible?(shipment, rate)
    end

    def details(shipment, rate, attributes, receiver:, shipper:)
      {
        **attributes,
        **receiver&.shipment_attributes(:receiver, shipment.receiver_address_id).to_h,
        **shipper&.shipment_attributes(:shipper, shipment.shipper_address_id).to_h,
        **attributes.slice(*HOURS).transform_values { |time| time&.strftime(HOURS_FORMAT) },
        quoted_delivery_by: attributes[:pickup_on]&.then { |pickup_on| rate.transit_days.to_i.business_days.after(pickup_on) }
      }.compact
    end

    def eligible?(shipment, rate)
      return true if user_type == :broker

      shipment.valid_broker_carriers_for_quotation(user_type).exists?(id: rate.broker_carrier_id)
    end

    def lane_changed?(shipment)
      [shipment.receiver_address, shipment.shipper_address].any? do |address|
        address.present? && address.changed.intersect?(LANE_ATTRIBUTES)
      end
    end

    def save_shipment(shipment, attributes = {})
      shipment.assign_attributes(attributes)
      shipment.updated_by = actor

      raise_record_errors(shipment) unless shipment.save && shipment.errors.none?
    end
  end
end
