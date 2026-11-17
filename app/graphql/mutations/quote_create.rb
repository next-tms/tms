module Mutations
  class QuoteCreate < BaseMutation
    include Mutations::Concerns::Rateable
    include Mutations::Concerns::Shippable

    argument :accessorial_codes, [String], default_value: [], replace_null_with_default: true, required: false
    argument :customer_id, ID, as: :broker_customer_id, required: false
    argument :declared_freight_classes, Boolean, default_value: false, replace_null_with_default: true, required: false
    argument :packages, [Types::PackageInputObject], required: true, validates: { length: { minimum: 1 } }
    argument :pickup_on, GraphQL::Types::ISO8601Date, required: false
    argument :receiver_address, Types::AddressInputObject, required: true
    argument :shipper_address, Types::AddressInputObject, required: true

    field :rates, [Types::RateType], null: false
    field :shipment, Types::ShipmentType, null: false

    def resolve(accessorial_codes:, declared_freight_classes:, packages:, broker_customer_id: nil, **attributes)
      shipment = Shipment.new(broker_customer: broker_customer_for(broker_customer_id), quote_only: true)

      authorize!(shipment, to: :create?)

      raise_error('Customer not found', 'NOT_FOUND') if shipment.broker_customer.blank?
      raise_error("Packages exceed #{Types::PackageInputObject::MAX_UNITS} units", 'TOO_MANY_UNITS') if too_many_units?(packages)

      shipment.assign_attributes(
        items_attributes: packages.map(&:item_attributes),
        pickup_on: attributes[:pickup_on],
        receiver_address_attributes: attributes[:receiver_address].address_attributes,
        shipment_broker_accessorials_attributes: shipment_broker_accessorials_attributes(shipment, accessorial_codes),
        shipper_address_attributes: attributes[:shipper_address].address_attributes
      )
      shipment.created_by = actor
      shipment.updated_by = actor

      raise_record_errors(shipment) unless shipment.save

      { rates: rates_for(shipment, declared_freight_classes:), shipment: }
    end

    private

    def too_many_units?(packages) = packages.sum(&:quantity) > Types::PackageInputObject::MAX_UNITS
  end
end
