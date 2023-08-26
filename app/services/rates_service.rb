# frozen_string_literal: true

class RatesService
  attr_reader :rates, :shipment, :broker_carrier, :use_forced_freight_classes

  UNSUPPORTED_DECLARED_VALUE_ERROR = StandardError.new('Carrier doesn’t support quoting shipments with declared value')
  NO_RATES_ERROR = StandardError.new('No rates returned from API')
  EMPTY_COST_ERROR = StandardError.new('Cost was empty')
  MISSING_SCAC_ERROR = StandardError.new('Carrier (acting as broker) API returned quote with missing carrier name and SCAC')

  def initialize(broker_carrier:, shipment:, use_forced_freight_classes:, save_new_rates: false)
    @broker_carrier = broker_carrier
    @rates = []
    @shipment = shipment
    @use_forced_freight_classes = use_forced_freight_classes
    @save_new_rates = save_new_rates
  end

  def call
    calculated_freight_classes = items.map(&:calculated_freight_class)
    forced_freight_classes = items.map(&:forced_freight_class)

    return if calculated_freight_classes.blank? && forced_freight_classes.blank?

    fetch_pricing_rule_rates
    fetch_api_rates

    rates
  end

  private

  def fetch_api_rates
    return if @broker_carrier.to_freight_kit_carrier.blank?

    response = nil

    ignore_value = @shipment.broker_customer&.ignore_value_on_api_quotes? || false
    carrier_finds_rate_with_declared_value = @broker_carrier.to_freight_kit_carrier.class.find_rates_with_declared_value?

    if !ignore_value && @shipment.value.positive? && !carrier_finds_rate_with_declared_value
      rate = build_rate(:api)
      rate.assign_attributes(error_object: UNSUPPORTED_DECLARED_VALUE_ERROR)
      @rates << rate
      rate.save! if @save_new_rates

      return
    end

    begin
      response = TransponderService.new(shipment:, broker_carrier:).rates(use_forced_freight_classes:)
    rescue StandardError => e
      if !Rails.env.development? && !e.is_a?(FreightKit::Error)
        attributes = {
          broker_carrier_id: @broker_carrier&.id,
          shipment_id: @shipment&.id,
          use_forced_freight_classes: @use_forced_freight_classes
        }

        Honeybadger.notify(e, attributes)
      end

      rate = build_rate(:api)
      rate.error_object = e
      begin
        rate.save! if @save_new_rates
      rescue
        rate.error_object = e.message
        rate.save! if @save_new_rates
      end

      @rates << rate

      return
    end

    transponder_rates = response[:rates]

    if transponder_rates.blank?
      rate = build_rate(:api)
      rate.assign_attributes(
        api_request: response[:request],
        api_response: response[:response],
        error_object: response.dig(:response, :error, :errormessage) || response[:error] || NO_RATES_ERROR,
      )
      @rates << rate
      rate.save! if @save_new_rates

      return
    end

    transponder_rates.each do |freight_kit_rate|
      rate = build_rate(:api)
      rate.assign_attributes(
        api_request: response[:request],
        api_response: response[:response],
        error_object: response.dig(:response, :error, :errormessage),
      )

      begin
        cost = Money.new(freight_kit_rate.dig(:totalCents, :value))
      rescue => e
        cost = 0
      end

      unless cost.positive?
        rate.assign_attributes(error_object: EMPTY_COST_ERROR)

        @rates << rate
        rate.save! if @save_new_rates

        next
      end

      # cost += @broker_carrier.quote_padding unless @broker_carrier.quote_padding.blank?

      tracking_carrier = nil
      if @broker_carrier.carrier.acts_as_broker?
        carrier_name = freight_kit_rate[:carrierName]
        carrier_scac = freight_kit_rate[:scac]

        if carrier_scac.blank? || carrier_name.blank?
          rate.assign_attributes(error_object: MISSING_SCAC_ERROR)

          @rates << rate
          rate.save! if @save_new_rates

          next
        end

        # Import carrier information
        tracking_carrier = (Carrier.find_by(scac: carrier_scac).presence || Carrier.create(
          name: carrier_name.titleize,
          scac: carrier_scac.upcase,
        ))
      end

      rate.assign_attributes(
        breakdown: freight_kit_rate[:prices],
        cost:,
        freight_kit_service_type: freight_kit_rate[:serviceName],
        reference: freight_kit_rate[:estimateReference],
        tracking_carrier:,
        transit_days: freight_kit_rate[:transitDays],
      )

      @rates << rate
      rate.save! if @save_new_rates
    end

    nil
  end

  def fetch_pricing_rule_rates
    return if @broker_carrier.pricing_rules.none?

    from_locations = Location
                     .where(zip_code: @shipment.shipper_address.zip_code)
                     .or(
                       Location.where(region: @shipment.shipper_address.region, zip_code: nil),
                     )
    to_locations = Location
                   .where(zip_code: @shipment.receiver_address.zip_code)
                   .or(
                     Location.where(region: @shipment.receiver_address.region, zip_code: nil),
                   )

    return unless from_locations.present? && to_locations.present?

    from_areas = Area.where(id: from_locations.map(&:areas).flatten.map(&:id))
    to_areas = Area.where(id: to_locations.map(&:areas).flatten.map(&:id))

    carrier_areas = @broker_carrier.carrier.carrier_areas.where(from_area: from_areas, to_area: to_areas)

    return if carrier_areas.blank?

    pallet_count = items.map(&:pallet_or_crate?).count(true)

    carrier_areas.find_each do |carrier_area|
      pricing_rule = @broker_carrier
                     .pricing_rules
                     .where(carrier_area:)
                     .where('min_pallets <= ?', pallet_count)
                     .where('max_pallets >= ?', pallet_count)
                     .first

      if pricing_rule.blank?
        pricing_rule = @broker_carrier
                       .pricing_rules
                       .where(carrier_area:)
                       .where('min_pallets <= ?', pallet_count)
                       .where(max_pallets: nil)
                       .first
      end

      next if pricing_rule.blank?

      cost = (Money.new(pricing_rule.cost_per_pallet * pallet_count) if pricing_rule.cost_per_pallet.present?)

      cost += @broker_carrier.quote_padding if cost.present? && @broker_carrier.quote_padding.present?

      rate = build_rate(:pricing_rule)
      rate.assign_attributes(cost:)
      @rates << rate
      rate.save! if @save_new_rates
    end

    nil
  end

  def build_rate(source)
    Rate.new(
      accessorials: Accessorial.combined_accessorials(shipment:),
      broker_carrier: @broker_carrier,
      broker_customer: @shipment.broker_customer,
      shipment_fingerprint: @shipment.fingerprint,
      shipment: @shipment,
      source:,
      with_calculated_freight_classes: !@use_forced_freight_classes,
    )
  end

  def items
    @items ||= @shipment.items
  end
end

# // Old code using FreightKit
# // TODO: Remove after Regression Testing
#
#
# class RatesService
#   attr_reader :rates, :shipment, :broker_carrier, :use_forced_freight_classes
#
#   UNSUPPORTED_DECLARED_VALUE_ERROR = StandardError.new("Carrier doesn’t support quoting shipments with declared value")
#   NO_RATES_ERROR = StandardError.new('No rates returned from API')
#   EMPTY_COST_ERROR = StandardError.new('Cost was empty')
#   MISSING_SCAC_ERROR = StandardError.new('Carrier (acting as broker) API returned quote with missing carrier name and SCAC')
#
#   def initialize(broker_carrier:, shipment:, use_forced_freight_classes:, save_new_rates: false)
#     @broker_carrier = broker_carrier
#     @rates = []
#     @shipment = shipment
#     @use_forced_freight_classes = use_forced_freight_classes
#     @save_new_rates = save_new_rates
#   end
#
#   def call
#     calculated_freight_classes = items.map(&:calculated_freight_class)
#     forced_freight_classes = items.map(&:forced_freight_class)
#
#     return if calculated_freight_classes.blank? && forced_freight_classes.blank?
#
#     fetch_pricing_rule_rates
#     fetch_api_rates
#
#     rates
#   end
#
#   private
#
#   def fetch_api_rates
#     return if @broker_carrier.to_freight_kit_carrier.blank?
#
#     response = nil
#
#     ignore_value = @shipment.broker_customer&.ignore_value_on_api_quotes? || false
#     carrier_finds_rate_with_declared_value = @broker_carrier.to_freight_kit_carrier.class.find_rates_with_declared_value?
#
#     if !ignore_value && @shipment.value.positive? && !carrier_finds_rate_with_declared_value
#       rate = build_rate(:api)
#       rate.assign_attributes(error_object: UNSUPPORTED_DECLARED_VALUE_ERROR)
#       @rates << rate
#       rate.save! if @save_new_rates
#
#       return
#     end
#
#     begin
#       response = TransponderService.new(shipment:, broker_carrier:).rates(use_forced_freight_classes:)
#     rescue StandardError => e
#
#       if !Rails.env.development? && !e.is_a?(FreightKit::Error)
#         attributes = {
#           broker_carrier_id: @broker_carrier&.id,
#           shipment_id: @shipment&.id,
#           use_forced_freight_classes: @use_forced_freight_classes
#         }
#
#         Honeybadger.notify(e, attributes)
#       end
#
#       rate = build_rate(:api)
#       rate.error_object = e
#       begin
#         rate.save! if @save_new_rates
#       rescue
#         rate.error_object = e.message
#         rate.save! if @save_new_rates
#       end
#
#       @rates << rate
#
#
#       return
#     end
#
#     freight_kit_rates = response[:rates]
#
#     if freight_kit_rates.blank?
#       rate = build_rate(:api)
#       rate.assign_attributes(
#         api_request: response[:request],
#         api_response: response[:response],
#         error_object: response.dig(:response, :error, :errormessage) || response[:error] || NO_RATES_ERROR
#       )
#       @rates << rate
#       rate.save! if @save_new_rates
#
#       return
#     end
#
#     freight_kit_rates.each do |freight_kit_rate|
#       rate = build_rate(:api)
#       rate.assign_attributes(
#         api_request: response[:request],
#         api_response: response[:response],
#         error_object: response.dig(:response, :error, :errormessage)
#       )
#
#       begin
#         cost = Money.new(freight_kit_rate.dig(:totalCents, :value))
#       rescue => e
#         cost = 0
#       end
#
#       unless cost.positive?
#         rate.assign_attributes(error_object: EMPTY_COST_ERROR)
#
#         @rates << rate
#         rate.save! if @save_new_rates
#
#         next
#       end
#
#       # cost += @broker_carrier.quote_padding unless @broker_carrier.quote_padding.blank?
#
#       tracking_carrier = nil
#       if @broker_carrier.carrier.acts_as_broker?
#         carrier_name = freight_kit_rate[:carrierName]
#         carrier_scac = freight_kit_rate[:scac]
#
#         if carrier_scac.blank? || carrier_name.blank?
#           rate.assign_attributes(error_object: MISSING_SCAC_ERROR)
#
#           @rates << rate
#           rate.save! if @save_new_rates
#
#           next
#         end
#
#         # Import carrier information
#         tracking_carrier = if Carrier.find_by_scac(carrier_scac).blank?
#                              Carrier.create(name: carrier_name.titleize, scac: carrier_scac.upcase)
#                            else
#                              Carrier.find_by_scac(carrier_scac)
#                            end
#       end
#
#       rate.assign_attributes(
#         breakdown: freight_kit_rate[:prices],
#         cost:,
#         freight_kit_service_type: freight_kit_rate[:serviceName],
#         reference: freight_kit_rate[:estimateReference],
#         tracking_carrier:,
#         transit_days: freight_kit_rate[:transitDays]
#       )
#
#       @rates << rate
#       rate.save! if @save_new_rates
#     end
#
#     nil
#   end
#
#   def fetch_pricing_rule_rates
#     return unless @broker_carrier.pricing_rules.any?
#
#     from_locations = Location
#                      .where(zip_code: @shipment.shipper_address.zip_code)
#                      .or(
#                        Location.where(region: @shipment.shipper_address.region, zip_code: nil)
#                      )
#     to_locations = Location
#                    .where(zip_code: @shipment.receiver_address.zip_code)
#                    .or(
#                      Location.where(region: @shipment.receiver_address.region, zip_code: nil)
#                    )
#
#     return unless from_locations.present? && to_locations.present?
#
#     from_areas = Area.where(id: from_locations.map(&:areas).flatten.map(&:id))
#     to_areas = Area.where(id: to_locations.map(&:areas).flatten.map(&:id))
#
#     carrier_areas = @broker_carrier.carrier.carrier_areas.where(from_area: from_areas, to_area: to_areas)
#
#     return if carrier_areas.blank?
#
#     pallet_count = items.map(&:pallet_or_crate?).count(true)
#
#     carrier_areas.find_each do |carrier_area|
#       pricing_rule = @broker_carrier
#                      .pricing_rules
#                      .where(carrier_area:)
#                      .where('min_pallets <= ?', pallet_count)
#                      .where('max_pallets >= ?', pallet_count)
#                      .first
#
#       if pricing_rule.blank?
#         pricing_rule = @broker_carrier
#                        .pricing_rules
#                        .where(carrier_area:)
#                        .where('min_pallets <= ?', pallet_count)
#                        .where(max_pallets: nil)
#                        .first
#       end
#
#       next if pricing_rule.blank?
#
#       cost = (Money.new(pricing_rule.cost_per_pallet * pallet_count) if pricing_rule.cost_per_pallet.present?)
#
#       cost += @broker_carrier.quote_padding if cost.present? && @broker_carrier.quote_padding.present?
#
#       rate = build_rate(:pricing_rule)
#       rate.assign_attributes(cost:)
#       @rates << rate
#       rate.save! if @save_new_rates
#     end
#
#     nil
#   end
#
#   def build_rate(source)
#     Rate.new(
#       accessorials: Accessorial.combined_accessorials(shipment:),
#       broker_carrier: @broker_carrier,
#       broker_customer: @shipment.broker_customer,
#       shipment_fingerprint: @shipment.fingerprint,
#       shipment: @shipment,
#       source:,
#       with_calculated_freight_classes: !@use_forced_freight_classes
#     )
#   end
#
#   def items
#     @items ||= @shipment.items
#   end
# end
#
