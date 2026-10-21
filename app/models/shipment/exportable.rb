module Shipment::Exportable
  extend ActiveSupport::Concern

  MISSING_DIMENSIONS = 'Unable to compute: some item(s) are missing dimensions'.freeze
  UNKNOWN_FREIGHT_CLASS = 'unknown'.freeze

  class_methods do
    def method_preloads
      {
        accessorial_list: [ :shipment_broker_accessorials, { broker_accessorials: :accessorial } ],
        average_density: :items,
        calculated_freight_class_list: :items,
        carrier_name: [ :tracking_carrier, { broker_carrier: :carrier } ],
        freight_class_list: :items,
        item_description_list: :items,
        item_summaries: { items: :packaging },
        loose_pieces_count: { items: :packaging },
        palletized_count: { items: :packaging },
        receiver_state: :receiver_address,
        shipper_state: :shipper_address,
        total_item_weight: :items
      }
    end
  end

  def accessorial_list
    broker_accessorials
      .reject(&:broker_only)
      .filter_map(&:accessorial)
      .uniq
      .map(&:name)
      .sort
      .join(', ')
      .downcase
  end

  def average_density
    return if items.empty?

    densities = items.map { |item| item.density(rounded: false) }
    return MISSING_DIMENSIONS if densities.any?(nil)

    (densities.sum / densities.size).round(2)
  end

  def calculated_freight_class_list = joined_freight_classes(items.map(&:calculated_freight_class))
  def carrier_name = carrier&.name
  def delivery_date = delivered_at&.in_time_zone(Setting.value!(:time_zone_name))&.to_date
  def freight_class_list = joined_freight_classes(items.map(&:display_freight_class))
  def item_description_list = items.filter_map(&:desc).uniq.join(', ')
  def item_summaries = items.map(&:summary).join("\n")
  def loose_pieces_count = items.reject(&:pallet_or_crate?).sum(&:quantity)
  def palletized_count = items.select(&:pallet_or_crate?).sum(&:quantity)
  def pickup_date = picked_up_at&.in_time_zone(Setting.value!(:time_zone_name))&.to_date
  def receiver_state = receiver_address&.region&.abbreviation
  def shipper_state = shipper_address&.region&.abbreviation
  def total_item_weight = items.sum { |item| item.weight.to_i }

  private

  def joined_freight_classes(freight_classes)
    freight_classes
      .sort_by { |freight_class| freight_class || Float::INFINITY }
      .map { |freight_class| freight_class || UNKNOWN_FREIGHT_CLASS }
      .join(', ')
  end
end
