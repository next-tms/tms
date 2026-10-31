class EBOL
  class << self
    def call(shipment) = new(shipment).call
  end

  ACCESSORIAL_CODES = {
    'appointment_delivery' => 'APTD',
    'appointment_pickup' => 'APTP',
    'guaranteed_delivery_am' => 'GTD_AM',
    'guaranteed_delivery_pm' => 'GTD_PM',
    'inside_delivery' => 'IDL',
    'inside_pickup' => 'IPU',
    'liftgate_delivery' => 'LFTD',
    'liftgate_pickup' => 'LFTP',
    'residential_delivery' => 'RES',
    'residential_pickup' => 'REP'
  }.freeze
  HANDLING_UNIT_TYPES = {
    'box' => 'BOX',
    'bundle' => 'BDL',
    'container' => 'CNT',
    'crate' => 'CRT',
    'cylinder' => 'CYL',
    'drum' => 'DRM',
    'pail' => 'PAL',
    'pallet' => 'PAT',
    'piece' => 'PCS',
    'roll' => 'ROL',
    'tote' => 'TBN',
    'truckload' => 'TRU'
  }.freeze
  VERSION = '2.1.0'.freeze

  attr_reader :shipment

  def initialize(shipment)
    @shipment = shipment
    ActiveRecord::Associations::Preloader.new(records: [shipment], associations: { items: :packaging }).call
  end

  def call
    {
      version: VERSION,
      bol:,
      referenceNumbers: reference_numbers,
      payment: { terms: 'Third Party' },
      commodities:,
      shipmentTotals: shipment_totals,
      accessorials:,
      origin:,
      destination:,
      billTo: bill_to
    }.compact
  end

  private

  def accessorials
    codes = shipment.accessorials.filter_map { |accessorial| ACCESSORIAL_CODES[accessorial.freight_kit_code] }
    codes << 'HAZ' if shipment.items.any?(&:hazmat?)
    { codes: codes.uniq } if codes.any?
  end

  def bill_to
    return party(name: billing_carrier.name, address: billing_carrier.broker_billing_address, contact: setting_contact) if billing_carrier

    { account: carrier_account, **party(name: Setting.value!(:name), address: Setting.mailing_address!, contact: setting_contact) }.compact
  end

  def billing_carrier
    (broker_carrier_carrier if broker_carrier_carrier&.acts_as_broker? && broker_carrier_carrier.broker_billing_address.present?)
  end

  def broker_carrier_carrier = shipment.broker_carrier&.carrier
  def carrier_account = (shipment.broker_carrier.account.presence if broker_carrier_carrier && !broker_carrier_carrier.acts_as_broker?)

  def bol
    {
      function: 'Create',
      isTest: false,
      requestedPickupDate: shipment.pickup_on&.strftime('%Y-%m-%dT00:00:00.000'),
      requestorRole: 'Third Party',
      specialInstructions: special_instructions
    }.compact
  end

  def classification(item) = item.api_freight_class(use_declared_freight_class: !shipment.calculated_freight_classes?)&.to_s
  def commodities = { lineItemLayout: 'Nested', handlingUnits: shipment.items.map { |item| handling_unit(item) } }
  def declared_value = shipment.value.positive? ? { declaredValue: shipment.value.to_i, currency: shipment.value.currency.iso_code } : {}

  def destination
    party(
      name: shipment.receiver_name,
      address: shipment.receiver_address,
      contact: {
        name: shipment.receiver_contact_name.presence,
        phone: phone(shipment.receiver_contact_phone),
        email: shipment.receiver_contact_email.presence
      }
    )
  end

  def handling_unit(item)
    {
      count: item.quantity,
      type: handling_unit_type(item),
      weight: item.weight,
      weightUnit: 'Pounds',
      length: item.l,
      width: item.w,
      height: item.h,
      dimensionsUnit: 'Inches',
      lineItems: [line_item(item)]
    }.compact
  end

  def handling_unit_type(item) = HANDLING_UNIT_TYPES.fetch(item.packaging.freight_kit_type, 'OTH')

  def line_item(item)
    {
      description: item.desc,
      weight: item.weight,
      weightUnit: 'Pounds',
      pieces: item.quantity,
      packagingType: handling_unit_type(item),
      classification: classification(item),
      nmfc: item.nmfc&.to_s,
      hazardous: item.hazmat?
    }.compact
  end

  def origin
    party(
      name: shipment.shipper_name,
      address: shipment.shipper_address,
      contact: {
        name: shipment.shipper_contact_name.presence,
        phone: phone(shipment.shipper_contact_phone),
        email: shipment.shipper_contact_email.presence
      }
    )
  end

  def party(name:, address:, contact:)
    {
      name:,
      address1: address.street,
      address2: address.street2.presence,
      city: address.city,
      stateProvince: address.region&.abbreviation,
      postalCode: address.zip_code,
      country: address.country&.alpha3,
      contact: contact.compact
    }.compact
  end

  def phone(number) = number.to_s.gsub(/\D/, '').last(10).presence

  def reference_numbers
    {
      pro: shipment.pro.presence,
      quoteId: shipment.quote_id.presence,
      shipmentId: shipment.load_id.to_s,
      bol: [shipment.bol, shipment.shipper_bol].compact_blank.presence,
      po: ([{ number: shipment.customer_reference }] if shipment.customer_reference.present?),
      additionalReferences: ([{ name: 'Shipper Reference', value: shipment.shipper_reference }] if shipment.shipper_reference.present?)
    }.compact
  end

  def setting_contact = { phone: phone(Setting.phone), email: Setting.customer_service_email }

  def shipment_totals
    {
      grossWeight: shipment.total_weight,
      weightUnit: 'Pounds',
      handlingUnits: shipment.total_pieces,
      cube: shipment.total_cubic_ft(rounded: true),
      cubeDimensionsUnit: 'Feet',
      **declared_value
    }.compact
  end

  def special_instructions
    [
      Setting.default_bol_notes,
      shipment.broker_carrier&.default_bol_notes,
      shipment.broker_customer&.default_bol_notes,
      shipment.bol_notes
    ].compact_blank.join("\n\n").presence
  end
end
