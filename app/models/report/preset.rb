class Report::Preset
  DEFINITIONS = {
    'customer-report' => {
      description: 'Delivered shipments with references, lanes, dates, items, and price.',
      headers: {
        'load_id' => 'Load',
        'shipper_reference' => 'SO',
        'customer_reference' => 'PO',
        'bol' => 'BOL',
        'carrier_name' => 'Carrier',
        'shipper_name' => 'Origin',
        'shipper_address.city' => 'Origin City',
        'shipper_state' => 'Origin State',
        'shipper_address.zip_code' => 'Origin ZIP Code',
        'receiver_name' => 'Destination',
        'receiver_address.city' => 'Destination City',
        'receiver_state' => 'Destination State',
        'receiver_address.zip_code' => 'Destination ZIP Code',
        'pickup_date' => 'Pickup Date',
        'delivery_date' => 'Delivery Date',
        'item_summaries' => 'Description',
        'average_density' => 'Average Density',
        'total_item_weight' => 'Total Weight (Pounds)',
        'palletized_count' => 'Palletized/Crated Count',
        'loose_pieces_count' => 'Loose Pieces Count',
        'total_charges' => 'Price',
        'freight_class_list' => 'Freight Class(es)',
        'accessorial_list' => 'Accessorials',
        'status' => 'Status'
      },
      filters: { 'status_in' => [ 'delivered' ] },
      name: 'Customer Report'
    },
    'freight-report' => {
      description: 'Shipments with lanes, item descriptions, density, weight, freight classes, and price.',
      headers: {
        'load_id' => 'Load',
        'shipper_address.zip_code' => 'Origin ZIP Code',
        'receiver_address.zip_code' => 'Destination ZIP Code',
        'item_description_list' => 'Description',
        'average_density' => 'Density',
        'total_item_weight' => 'Weight (lbs)',
        'palletized_count' => 'Palletized/Crated',
        'loose_pieces_count' => 'Non-Palletized/Crated',
        'calculated_freight_class_list' => 'Freight Class(es)',
        'accessorial_list' => 'Accessorials',
        'total_charges' => 'Price'
      },
      filters: {},
      name: 'Freight Report'
    }
  }.freeze

  include Report::Runnable

  class << self
    def all = DEFINITIONS.keys.map { |key| new(key) }
    def find(key) = (new(key) if DEFINITIONS.key?(key))
    def policy_class = ReportPolicy
  end

  attr_reader :key

  def initialize(key)
    @key = key
  end

  def cache_key = "report/presets/#{key}/#{Digest::MD5.hexdigest(definition.to_json)}"
  def columns = headers.keys
  def date_attribute = 'created_at'
  def description = definition[:description]
  def filters = definition[:filters]
  def from_days_ago = nil
  def headers = definition[:headers]
  def name = definition[:name]
  def preset? = true
  def record_type = 'Shipment'
  def to_days_ago = nil

  def to_param = key

  private

  def definition = DEFINITIONS.fetch(key)
end
