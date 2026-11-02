class EBOL::Importer::Item
  class << self
    def call(handling_unit) = new(handling_unit).call
  end

  attr_reader :handling_unit

  def initialize(handling_unit)
    @handling_unit = handling_unit
  end

  def call
    {
      declared_freight_class: line_items.filter_map { |line_item| Float(line_item[:classification], exception: false) }.max,
      desc: line_items.filter_map { |line_item| line_item[:description].presence }.join(', ').presence || 'Freight',
      hazmat: line_items.any? { |line_item| DSDC.boolean(line_item[:hazardous]) },
      measured_h: length(:height),
      measured_l: length(:length),
      measured_w: length(:width),
      measured_weight: measure(Measured::Weight, handling_unit[:weight], handling_unit[:weightUnit], :lb),
      nmfc: line_items.first&.then { |line_item| [line_item[:nmfc], line_item[:nmfcSub]].compact_blank.join('-').presence },
      packaging: Packaging.find_by(freight_kit_type: EBOL.freight_kit_type(handling_unit[:type])),
      quantity: handling_unit[:count]
    }
  end

  private

  def length(dimension) = measure(Measured::Length, handling_unit[dimension], handling_unit[:dimensionsUnit], :in)
  def line_items = Array(handling_unit[:lineItems])

  def measure(measurable, value, unit, default_unit)
    return if value.blank?

    unit = unit.to_s.downcase

    measurable.new(value, measurable.unit_or_alias?(unit) ? unit : default_unit)
  end
end
