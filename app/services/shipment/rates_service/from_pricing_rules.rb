class Shipment::RatesService
  class FromPricingRules < Base
    def call
      return rates if broker_carrier.pricing_rules.none?

      from_locations = Location
                       .where(zip_code: shipment.shipper_address.zip_code)
                       .or(
                         Location.where(region_iso31662: shipment.shipper_address.region_iso31662, zip_code: nil),
                       )
      to_locations = Location
                     .where(zip_code: shipment.receiver_address.zip_code)
                     .or(
                       Location.where(region_iso31662: shipment.receiver_address.region_iso31662, zip_code: nil),
                     )

      return rates unless from_locations.present? && to_locations.present?

      from_areas = Area.where(id: from_locations.map(&:areas).flatten.map(&:id))
      to_areas = Area.where(id: to_locations.map(&:areas).flatten.map(&:id))

      carrier_areas = broker_carrier.carrier.carrier_areas.where(from_area: from_areas, to_area: to_areas)

      return rates if carrier_areas.blank?

      pallet_count = shipment.items.map(&:pallet_or_crate?).count(true)

      carrier_areas.find_each do |carrier_area|
        pricing_rule = broker_carrier
                       .pricing_rules
                       .where(carrier_area:)
                       .where('min_pallets <= ?', pallet_count)
                       .where('max_pallets >= ?', pallet_count)
                       .first

        if pricing_rule.blank?
          pricing_rule = broker_carrier
                         .pricing_rules
                         .where(carrier_area:)
                         .where('min_pallets <= ?', pallet_count)
                         .where(max_pallets: nil)
                         .first
        end

        next if pricing_rule.blank?

        cost = (Money.new(pricing_rule.cost_per_pallet * pallet_count) if pricing_rule.cost_per_pallet.present?)

        cost += broker_carrier.quote_padding if cost.present? && broker_carrier.quote_padding.present?

        rate = build_rate(:pricing_rule)
        rate.assign_attributes(cost:)
        @rates << rate
        rate.save! if save?
      end

      rates
    end
  end
end
