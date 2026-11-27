module BrokerWare
  class << self
    def accessorial_code(accessorial) = ACCESSORIAL_CODES[accessorial&.transponder_code&.to_sym] || accessorial&.code
    def camelize(key) = key.to_s.gsub(/_([a-z\d])/) { Regexp.last_match(1).upcase }
    def date(value) = Date.strptime(value.to_s[/\A\d{4}-\d{1,2}-\d{1,2}/].to_s, '%Y-%m-%d')
    def document_list_type(attachment) = DOCUMENT_LIST_TYPES[attachment.name.to_sym]
    def document_name(attachment) = DOCUMENT_NAMES[attachment.name.to_sym]
    def freight_kit_type(packaging) = PACKAGING_TYPES.fetch(packaging.to_s.downcase.to_sym, :pallet)
    def shipment_status(shipment) = SHIPMENT_STATUSES[shipment.status&.to_sym]
    def status_name(shipment) = shipment_status(shipment).to_s.camelize.presence

    def statuses(shipment_status)
      shipment_status = shipment_status.to_s.underscore.to_sym
      shipment_status = STATUS_ALIASES.fetch(shipment_status, shipment_status)

      SHIPMENT_STATUSES.select { |_status, broker_ware_status| compact_status(broker_ware_status) == compact_status(shipment_status) }.keys
    end

    def timestamp(date, hours = nil) = date && Time.find_zone('UTC').parse("#{date} #{hours.presence || '0:00'}")&.iso8601
    def transponder_code(accessorial_code) = ACCESSORIAL_CODES.key(accessorial_code.to_s.upcase)

    private

    def compact_status(status) = status.to_s.delete('_')
  end

  ACCESSORIAL_CODES = {
    appointment_delivery: 'APTD',
    construction_delivery: 'CSDE',
    construction_pickup: 'CSPK',
    convention_delivery: 'TSDE',
    convention_pickup: 'TSPK',
    dock_dropoff: 'DKDE',
    dock_pickup: 'DKPK',
    driver_assist: 'DRAS',
    grocery_warehouse_delivery: 'GRWE',
    grocery_warehouse_pickup: 'GRWP',
    inside_delivery: 'INDE',
    inside_pickup: 'INPK',
    liftgate_delivery: 'LGDE',
    liftgate_pickup: 'LGPK',
    limited_access_delivery: 'LIDE',
    limited_access_pickup: 'LIPK',
    mine_site_delivery: 'MNDE',
    notify_before_delivery: 'CALL',
    residential_delivery: 'RSDE',
    residential_pickup: 'RSPK',
    storage_facility_delivery: 'SFDE',
    storage_facility_pickup: 'SFPK'
  }.freeze
  DATE_FORMAT = '%-m/%-d/%Y'.freeze
  DOCUMENT_LIST_TYPES = { broker_bol: 1, broker_label: 3, broker_quote: 0 }.freeze
  DOCUMENT_NAMES = { broker_bol: 'BOL', broker_label: 'Label', broker_quote: 'Quote', carrier_pod: 'POD' }.freeze
  KEY_FORMAT = method(:camelize).to_proc.freeze
  PACKAGING_TYPES = {
    boxes: :box,
    buckets: :pail,
    bundles: :bundle,
    cartons: :box,
    cases: :box,
    coils: :roll,
    containers: :container,
    crates: :crate,
    cylinders: :cylinder,
    drums: :drum,
    ftl: :truckload,
    packages: :box,
    pails: :pail,
    pieces: :piece,
    reels: :roll,
    rolls: :roll,
    totes: :tote,
    truckloads: :truckload
  }.freeze
  SHIPMENT_STATUSES = {
    booked: :booked,
    booked_quoted: :booked,
    canceled: :canceled,
    delivered: :delivered,
    delivery_scheduled: :in_transit,
    dispatched: :dispatched,
    in_transit: :in_transit,
    new_shipment: :quoted,
    out_for_delivery: :out_for_delivery,
    pending_delivery_appointment: :in_transit,
    pickup_scheduled: :dispatched,
    quoted: :quoted
  }.freeze
  STATUS_ALIASES = { dispatch: :dispatched, dispatchnotcovered: :booked, pending: :booked }.freeze
end
