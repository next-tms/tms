class BrokerWare::ShipmentPayload < BrokerWare::Quote
  CANCELED_STATUSES = %i[canceled canceled_with_charges].freeze
  CONTACT_ATTRIBUTES = {
    bol_notes: :bill_of_landing_note,
    customer_reference: :po_reference,
    receiver_contact_email: :consignee_email,
    receiver_contact_name: :consignee_contact,
    receiver_contact_phone: :consignee_phone,
    shipper_contact_email: :shipper_email,
    shipper_contact_name: :shipper_contact,
    shipper_contact_phone: :shipper_phone,
    shipper_reference: :shipper_number
  }.freeze
  HOURS_ATTRIBUTES = {
    delivery_hours_end_at: :estimated_delivery_close_time,
    delivery_hours_start_at: :estimated_delivery_open_time,
    pickup_hours_end_at: :pickup_close_time,
    pickup_hours_start_at: :pickup_open_time
  }.freeze
  HOURS_FORMAT = '%-l:%M %p'.freeze
  OPEN_STATUSES = %i[booked quoted].freeze
  STOP_ATTRIBUTES = {
    receiver: {
      country: :consignee_country,
      name: :consignee_name,
      street: :consignee_address,
      street2: :consignee_address2,
      zip: :consignee_zip
    },
    shipper: {
      country: :shipper_country,
      name: :shipper_name,
      street: :shipper_address,
      street2: :shipper_address2,
      zip: :shipper_zip
    }
  }.freeze
  PERMITTED = [
    *BrokerWare::Quote::PERMITTED.grep(Symbol),
    *CONTACT_ATTRIBUTES.values,
    *HOURS_ATTRIBUTES.values,
    *STOP_ATTRIBUTES.values.flat_map(&:values),
    :load_id,
    :pickup_date,
    :rate_quote_id,
    :shipment_status,
    *BrokerWare::Quote::PERMITTED.grep(Hash)
  ].uniq.freeze
  ROOT_KEYS = PERMITTED.flat_map { |key| key.is_a?(Hash) ? key.keys : key }.map { |key| BrokerWare.camelize(key) }.sort.freeze

  attr_reader :shipment

  validate :validate_hours
  validate :validate_status

  def initialize(params, shipment:)
    @shipment = shipment
    super(params, broker_customer: shipment.broker_customer)
  end

  def cancel? = CANCELED_STATUSES.include?(status)
  def provided?(key) = shipment.new_record? || params.key?(key)
  def status = params[:shipment_status].to_s.delete(' ').underscore.presence&.to_sym

  def shipment_attributes
    {
      **provided_attributes(CONTACT_ATTRIBUTES) { |key| params[key].presence },
      **provided_attributes(HOURS_ATTRIBUTES) { |key| hours(params[key]) },
      **{
        items_attributes: (items_attributes if provided?(:items)),
        pickup_on: (pickup_on if provided?(:pickup_date)),
        receiver_address_attributes: address_attributes(:receiver),
        shipment_accessorials_attributes: (shipment_accessorials_attributes if provided?(:accessorials)),
        shipper_address_attributes: address_attributes(:shipper)
      }.compact
    }
  end

  private

  def address_attributes(stop)
    keys = STOP_ATTRIBUTES[stop]
    return unless keys.values.any? { |key| provided?(key) }

    {
      id: shipment.public_send(:"#{stop}_address_id"),
      **(provided?(keys[:zip]) ? location(stop).to_h : {}),
      **provided_attributes(keys.slice(:name, :street, :street2)) { |key| params[key].presence }
    }
  end

  def hours(value) = value.presence&.then { |time| Time.iso8601(time).strftime(HOURS_FORMAT) }

  def items_attributes
    [*shipment.items.map { |item| { _destroy: true, id: item.id } }, *items.map { |item| item_attributes(item) }]
  end

  def location(stop) = stop == :receiver ? receiver_location : shipper_location
  def pickup_on = params[:pickup_date].presence&.then { |time| Time.iso8601(time).to_date }
  def provided_attributes(attributes, &) = attributes.select { |_attribute, key| provided?(key) }.transform_values(&)

  def shipment_accessorials_attributes
    [
      *shipment.shipment_accessorials.map { |shipment_accessorial| { _destroy: true, id: shipment_accessorial.id } },
      *accessorials.map { |accessorial| { accessorial: } }
    ]
  end

  def validate_hours
    [*HOURS_ATTRIBUTES.values, :pickup_date].each do |key|
      Time.iso8601(params[key]) if params[key].present?
    rescue ArgumentError
      errors.add(key, :invalid)
    end
  end

  def validate_status
    return if status.blank? || cancel? || OPEN_STATUSES.include?(status)

    errors.add(:shipment_status, :unsupported)
  end
end
