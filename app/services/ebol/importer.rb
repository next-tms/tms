class EBOL::Importer
  ADDRESS = %i[address1 address2 city country name postalCode stateProvince].freeze
  CONTACT = %i[email name phone phoneExt].freeze
  DATE_RANGE = %i[end start].freeze
  HAZARDOUS_DETAILS = %i[class contractNumber packingGroup propername technicalName unnaNumber weight weightUnit].freeze
  LINE_ITEM = [
    :classification,
    :description,
    :hazardous,
    :hazardousDescription,
    :nmfc,
    :nmfcSub,
    :packagingType,
    :pieces,
    :weight,
    :weightUnit,
    { hazardousDetails: HAZARDOUS_DETAILS }
  ].freeze
  HANDLING_UNIT = [
    :count,
    :dimensionsUnit,
    :height,
    :length,
    :stackable,
    :tareWeight,
    :type,
    :weight,
    :weightUnit,
    :width,
    { lineItems: [LINE_ITEM] }
  ].freeze
  LOCATION = [*ADDRESS, :account, :locationId, { contact: CONTACT }].freeze
  PERMITTED = [
    :version,
    {
      accessorials: [
        {
          appointmentDetails: { delivery: DATE_RANGE, pickup: DATE_RANGE },
          cod: [:amount, :currency, :customerCheckAcceptable, :terms, { remitTo: ADDRESS }],
          codes: [],
          fullValueCoverageDetails: %i[currency monetaryValue],
          hazardousDetails: { emergencyContact: %i[name phone] },
          limitedAccessType: %i[destination origin],
          markDetails: %i[pieces],
          sortAndSegregateDetails: %i[pieces],
          timeCriticalDetails: [:type, { date: DATE_RANGE }]
        }
      ],
      billTo: LOCATION,
      bol: %i[function isTest requestedPickupDate requestorRole specialInstructions],
      commodities: [:lineItemLayout, { handlingUnits: [HANDLING_UNIT] }],
      customsBroker: [*ADDRESS, :type, { contact: CONTACT }],
      destination: LOCATION,
      images: [
        :includeBol,
        :includeShippingLabels,
        { email: [:includeBol, :includeLabels, { addresses: [] }], shippingLabels: %i[format position quantity] }
      ],
      notifications: [%i[email phoneNumber]],
      origin: LOCATION,
      payment: %i[terms],
      referenceNumbers: [
        :manifestId,
        :masterBol,
        :pro,
        :quoteId,
        :shipmentId,
        :trailerId,
        {
          additionalReferences: [%i[name value]],
          bol: [],
          po: [%i[additionalShipperInfo number palletized pieces weight weightUnit]]
        }
      ],
      shipmentTotals: %i[
        cube
        cubeDimensionsUnit
        currency
        declaredValue
        dimensionsUnit
        grossWeight
        handlingUnits
        linearLength
        netWeight
        weightUnit
      ]
    }
  ].freeze
  ROOT_KEYS = PERMITTED.flat_map { |entry| entry.is_a?(Hash) ? entry.keys : entry }.map(&:to_s).freeze

  attr_reader :information, :params

  def initialize(params)
    @information = []
    @params = params
  end

  def accessorial_codes = Array(params.dig(:accessorials, :codes))
  def bill_to_account = params.dig(:billTo, :account)
  def include_bol? = DSDC.boolean(params.dig(:images, :includeBol))
  def include_shipping_labels? = DSDC.boolean(params.dig(:images, :includeShippingLabels))

  def shipment_attributes(shipment)
    accessorials = Accessorials.new(accessorial_codes, shipment)

    accessorials.unsupported_codes.each do |code|
      information << { code: '200', message: I18n.t('dsdc.bols.unsupported_accessorial', code:), type: 'Warning' }
    end

    {
      bol: Array(params.dig(:referenceNumbers, :bol)).first,
      bol_notes: params.dig(:bol, :specialInstructions),
      customer_reference: Array(params.dig(:referenceNumbers, :po)).first&.dig(:number),
      items_attributes: items_attributes(shipment),
      lift_gate_delivery: accessorial_codes.include?('LFTD'),
      lift_gate_pickup: accessorial_codes.include?('LFTP'),
      pickup_hours_end_at: hours(params.dig(:accessorials, :appointmentDetails, :pickup, :end)),
      pickup_hours_start_at: hours(params.dig(:accessorials, :appointmentDetails, :pickup, :start)),
      pickup_on: params.dig(:bol, :requestedPickupDate).presence&.then { |date| Date.iso8601(date) },
      quote_id: params.dig(:referenceNumbers, :quoteId),
      receiver_address_attributes: Location.call(params[:destination], shipment.receiver_address),
      receiver_contact_email: params.dig(:destination, :contact, :email),
      receiver_contact_name: params.dig(:destination, :contact, :name),
      receiver_contact_phone: params.dig(:destination, :contact, :phone),
      shipment_accessorials_attributes: accessorials.shipment_accessorials_attributes,
      shipper_address_attributes: Location.call(params[:origin], shipment.shipper_address),
      shipper_contact_email: params.dig(:origin, :contact, :email),
      shipper_contact_name: params.dig(:origin, :contact, :name),
      shipper_contact_phone: params.dig(:origin, :contact, :phone),
      shipper_reference: params.dig(:referenceNumbers, :shipmentId),
      value_currency: params.dig(:shipmentTotals, :currency),
      value: params.dig(:shipmentTotals, :declaredValue)
    }.compact
  end

  def test? = DSDC.boolean(params.dig(:bol, :isTest))

  private

  def hours(value) = value.to_s.include?(':') ? Time.iso8601(value).strftime('%-l:%M %p') : nil

  def items_attributes(shipment)
    handling_units = params.dig(:commodities, :handlingUnits)
    return if handling_units.blank?

    [
      *shipment.items.map { |item| { _destroy: true, id: item.id } },
      *handling_units.map { |handling_unit| Item.call(handling_unit) }
    ]
  end
end
