class EBOL::Exporter
  class << self
    def call(shipment) = new(shipment).call
  end

  attr_reader :shipment

  def initialize(shipment)
    @shipment = shipment
    ActiveRecord::Associations::Preloader.new(records: [shipment], associations: { items: :packaging }).call
  end

  def call
    {
      accessorials:,
      billTo: bill_to,
      bol:,
      commodities:,
      destination:,
      origin:,
      payment: { terms: 'Third Party' },
      referenceNumbers: reference_numbers,
      shipmentTotals: shipment_totals,
      version: EBOL::VERSION
    }.compact
  end

  private

  def accessorials
    codes = EBOL.accessorial_codes(shipment.accessorials)
    codes << 'HAZ' if shipment.items.any?(&:hazmat?)
    { codes: codes.uniq } if codes.any?
  end

  def bill_to
    return party(address: billing_carrier.broker_billing_address, contact: setting_contact, name: billing_carrier.name) if billing_carrier

    { account: carrier_account, **party(address: Setting.mailing_address!, contact: setting_contact, name: Setting.value!(:name)) }.compact
  end

  def billing_carrier
    (broker_carrier_carrier if broker_carrier_carrier&.acts_as_broker? && broker_carrier_carrier.broker_billing_address.present?)
  end

  def bol
    {
      function: 'Create',
      isTest: false,
      requestedPickupDate: shipment.pickup_on&.strftime('%Y-%m-%dT00:00:00.000'),
      requestorRole: 'Third Party',
      specialInstructions: special_instructions
    }.compact
  end

  def broker_carrier_carrier = shipment.broker_carrier&.carrier
  def carrier_account = (shipment.broker_carrier.account.presence if broker_carrier_carrier && !broker_carrier_carrier.acts_as_broker?)
  def classification(item) = item.api_freight_class(use_declared_freight_class: !shipment.calculated_freight_classes?)&.to_s
  def commodities = { handlingUnits: shipment.items.map { |item| handling_unit(item) }, lineItemLayout: 'Nested' }
  def declared_value = shipment.value.positive? ? { currency: shipment.value.currency.iso_code, declaredValue: shipment.value.to_i } : {}

  def destination
    party(
      address: shipment.receiver_address,
      contact: {
        email: shipment.receiver_contact_email.presence,
        name: shipment.receiver_contact_name.presence,
        phone: phone(shipment.receiver_contact_phone)
      },
      name: shipment.receiver_address.name
    )
  end

  def handling_unit(item)
    {
      count: item.quantity,
      dimensionsUnit: 'Inches',
      height: item.h,
      length: item.l,
      lineItems: [line_item(item)],
      type: EBOL.handling_unit_type(item.packaging),
      weight: item.weight,
      weightUnit: 'Pounds',
      width: item.w
    }.compact
  end

  def line_item(item)
    {
      classification: classification(item),
      description: item.desc,
      hazardous: item.hazmat?,
      nmfc: item.nmfc&.to_s,
      packagingType: EBOL.handling_unit_type(item.packaging),
      pieces: item.quantity,
      weight: item.weight,
      weightUnit: 'Pounds'
    }.compact
  end

  def origin
    party(
      address: shipment.shipper_address,
      contact: {
        email: shipment.shipper_contact_email.presence,
        name: shipment.shipper_contact_name.presence,
        phone: phone(shipment.shipper_contact_phone)
      },
      name: shipment.shipper_address.name
    )
  end

  def party(address:, contact:, name:)
    {
      address1: address.street,
      address2: address.street2.presence,
      city: address.city,
      contact: contact.compact,
      country: address.country&.alpha3,
      name:,
      postalCode: address.zip_code,
      stateProvince: address.region&.abbreviation
    }.compact
  end

  def phone(number) = number.to_s.gsub(/\D/, '').last(10).presence

  def reference_numbers
    {
      additionalReferences: ([{ name: 'Shipper Reference', value: shipment.shipper_reference }] if shipment.shipper_reference.present?),
      bol: [shipment.bol, shipment.shipper_bol].compact_blank.presence,
      po: ([{ number: shipment.customer_reference }] if shipment.customer_reference.present?),
      pro: shipment.pro.presence,
      quoteId: shipment.quote_id.presence,
      shipmentId: shipment.load_id.to_s
    }.compact
  end

  def setting_contact = { email: Setting.customer_service_email, phone: phone(Setting.phone) }

  def shipment_totals
    {
      cube: shipment.total_cubic_ft(rounded: true),
      cubeDimensionsUnit: 'Feet',
      grossWeight: shipment.total_weight,
      handlingUnits: shipment.total_pieces,
      weightUnit: 'Pounds',
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
