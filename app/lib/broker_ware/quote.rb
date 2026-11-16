class BrokerWare::Quote
  include ActiveModel::Validations

  ITEM_ATTRIBUTES = %i[
    billed
    class
    container_number
    cost
    density
    height
    is_hazardous
    length
    nmfc
    packaging
    pieces
    product_description
    seal_number
    units_density
    units_dimension
    units_weight
    weight
    width
  ].freeze
  PERMITTED = [:consignee_country, :consignee_zip, :shipper_country, :shipper_zip, { accessorials: [], items: [ITEM_ATTRIBUTES] }].freeze
  ROOT_KEYS = PERMITTED.flat_map { |key| key.is_a?(Hash) ? key.keys : key }.map { |key| BrokerWare.camelize(key) }.sort.freeze

  attr_reader :broker_customer, :params

  validates :items, presence: true, if: -> { provided?(:items) }
  validate :validate_accessorials
  validate :validate_locations

  def initialize(params, broker_customer:)
    @broker_customer = broker_customer
    @params = params.to_h.deep_symbolize_keys
  end

  def accessorial_codes = Array(params[:accessorials]).compact_blank.map { |accessorial_code| accessorial_code.to_s.upcase }.uniq
  def declared_freight_classes? = items.all? { |item| item[:class].present? }
  def items = Array(params[:items])
  def provided?(_key) = true
  def read_attribute_for_validation(attribute) = respond_to?(attribute) ? public_send(attribute) : params[attribute]
  def receiver_location = @receiver_location ||= BrokerWare::Location.call(params[:consignee_zip], params[:consignee_country])
  def shipper_location = @shipper_location ||= BrokerWare::Location.call(params[:shipper_zip], params[:shipper_country])

  def shipment_attributes
    {
      items_attributes: items.map { |item| item_attributes(item) },
      receiver_address_attributes: receiver_location,
      shipment_broker_accessorials_attributes: broker_accessorials.ids.map { |broker_accessorial_id| { broker_accessorial_id: } },
      shipper_address_attributes: shipper_location
    }
  end

  private

  def broker_accessorials
    @broker_accessorials ||= broker_customer
                             .eligible_broker_accessorials
                             .joins(:accessorial)
                             .merge(Accessorial.where(code: accessorial_codes).or(Accessorial.where(freight_kit_code: freight_kit_codes)))
  end

  def freight_kit_codes = accessorial_codes.filter_map { |accessorial_code| BrokerWare.freight_kit_code(accessorial_code) }

  def inches(item, dimension)
    unit = item[:units_dimension].to_s.downcase.start_with?('c') ? :cm : :in
    Measured::Length.new(item[dimension].to_f, unit).convert_to(:in).value.round.nonzero?
  end

  def item_attributes(item)
    {
      declared_freight_class: item[:class].presence&.to_f,
      desc: item[:product_description].presence || 'Freight',
      h: inches(item, :height),
      hazmat: ActiveModel::Type::Boolean.new.cast(item[:is_hazardous]) || false,
      l: inches(item, :length),
      nmfc: (item[:nmfc].to_s unless item[:nmfc].to_i.zero?),
      packaging: Packaging.find_by(freight_kit_type: BrokerWare.freight_kit_type(item[:packaging])),
      quantity: item[:pieces].to_i,
      w: inches(item, :width),
      weight: pounds(item)
    }
  end

  def pounds(item)
    unit = item[:units_weight].to_s.downcase.start_with?('k') ? :kg : :lb
    Measured::Weight.new(item[:weight].to_f, unit).convert_to(:lb).value.ceil
  end

  def serviceable_codes
    Accessorial.where(id: broker_accessorials.select(:accessorial_id)).flat_map do |accessorial|
      [accessorial.code, BrokerWare.accessorial_code(accessorial)]
    end
  end

  def validate_accessorials
    unserviceable_codes = accessorial_codes - serviceable_codes
    errors.add(:accessorials, :unserviceable, codes: unserviceable_codes.join(', ')) if unserviceable_codes.any?
  end

  def validate_locations
    errors.add(:consignee_zip, :unknown) if provided?(:consignee_zip) && receiver_location.nil?
    errors.add(:shipper_zip, :unknown) if provided?(:shipper_zip) && shipper_location.nil?
  end
end
