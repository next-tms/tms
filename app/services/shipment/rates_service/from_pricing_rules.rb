class Shipment::RatesService
  class FromPricingRules < Base
    def call
      return rates unless served?

      pallet_count = shipment.items.map(&:pallet_or_crate?).count(true)
      pricing_rule = lane_ids.lazy.filter_map { |lane_id| pricing_rule_for(lane_id, pallet_count) }.first

      rate = build_rate(:pricing_rule)
      rate.assign_attributes(cost: cost(pricing_rule, pallet_count))
      @rates << rate
      rate.save! if save?

      rates
    end

    private

    def carrier = broker_carrier.carrier

    def cost(pricing_rule, pallet_count)
      return Money.new(0) if pricing_rule.blank?

      cost = Money.new(pricing_rule.cost_per_pallet * pallet_count)
      broker_carrier.quote_padding.present? ? cost + broker_carrier.quote_padding : cost
    end

    def lane_ids = @lane_ids ||= carrier.transponder_lanes.present? ? carrier.transponder_matching_lanes(**points).map(&:id) : []
    def points = { destination: shipment.receiver_address, origin: shipment.shipper_address }

    def pricing_rule_for(lane_id, pallet_count)
      pricing_rules = broker_carrier.pricing_rules.where(lane_id:)

      pricing_rules.where(max_pallets: pallet_count.., min_pallets: ..pallet_count).first ||
        pricing_rules.where(max_pallets: nil, min_pallets: ..pallet_count).first
    end

    def served? = lane_ids.any? || (carrier.transponder_territories.present? && carrier.transponder_serve?(**points))
  end
end
