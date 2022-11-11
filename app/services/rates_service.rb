# frozen_string_literal: true

class RatesService
  attr_reader :rates

  def initialize(broker_carrier:, shipment:, use_forced_freight_classes:)
    @broker_carrier = broker_carrier
    @rates = []
    @shipment = shipment
    @use_forced_freight_classes = use_forced_freight_classes
  end

  def call
    calculated_freight_classes = items.map(&:calculated_freight_class)
    forced_freight_classes = items.map(&:forced_freight_class)

    return if calculated_freight_classes.blank? && forced_freight_classes.blank?

    fetch_pricing_rule_rates
    # fetch_api_rates

    nil
  end

  # @deprecated Use call, then rates
  # @todo Remove
  def to_rates
    call
    rates
  end

  private

  def combined_accessorials
    @combined_accessorials ||= Accessorial
                               .distinct
                               .where(
                                 id: @shipment.accessorials.pluck(:id) +
                                     @shipment.assumed_accessorials.pluck(:id)
                               )
  end

  def fetch_api_rates
    return if @broker_carrier.as_interstellar_carrier.blank?

    response = nil

    ignore_value = if @shipment.broker_customer.blank?
                     false
                   else
                     @shipment.broker_customer.ignore_value_on_api_quotes?
                   end

    if !ignore_value &&
       !@shipment.value.zero? &&
       !@broker_carrier.as_interstellar_carrier.find_rates_with_declared_value?
      error = StandardError.new('Carrier doesn’t support quoting shipments with declared value')

      rate = build_rate(:api)
      rate.assign_attributes(error_object: error)
      @rates << rate

      return
    end

    api_shipment = Interstellar::Shipment.new(
      accessorials:,
      declared_value_cents: @shipment.value_cents,
      origin: @shipment.shipper_address.to_interstellar_shipping_address,
      destination: @shipment.receiver_address.to_interstellar_shipping_address,
      packages:,
      pickup_at:
    )

    begin
      response = InterstellarApiClient.fetch_rates(
        broker_carrier: @broker_carrier,
        shipment: api_shipment
      )
    rescue StandardError => e
      if !Rails.env.development? && !e.is_a?(Interstellar::Error)
        attributes = {
          broker_carrier_id: @broker_carrier&.id,
          shipment_id: @shipment&.id,
          use_forced_freight_classes: @use_forced_freight_classes
        }

        Honeybadger.notify(e, attributes)
      end

      rate = build_rate(:api)
      rate.error_object = e
      @rates << rate

      return
    end

    interstellar_rates = response&.rates

    if interstellar_rates.blank?
      rate = build_rate(:api)
      rate.assign_attributes(
        api_request: response&.request,
        api_response: response&.response,
        error_object: response&.error || StandardError.new('No rates returned from API')
      )
      @rates << rate

      return
    end

    interstellar_rates.each do |interstellar_rate|
      rate = build_rate(:api)
      rate.assign_attributes(
        api_request: response.request,
        api_response: response.response,
        error_object: response.error
      )

      cost = Money.new(interstellar_rate.total_cents)

      unless cost.positive?
        rate.assign_attributes(error_object: StandardError.new('Cost was empty'))

        @rates << rate
        next
      end

      # cost += @broker_carrier.quote_padding unless @broker_carrier.quote_padding.blank?
      breakdown = interstellar_rate.prices

      tracking_carrier = nil
      if @broker_carrier.carrier.acts_as_broker?
        carrier_name = interstellar_rate.carrier_name
        carrier_scac = interstellar_rate.scac

        if carrier_scac.blank? || carrier_name.blank?
          rate.assign_attributes(
            error_object: StandardError.new(
              'Carrier (acting as broker) API returned quote with missing carrier name and SCAC'
            )
          )

          @rates << rate
          next
        end

        # Import carrier information
        tracking_carrier = if Carrier.find_by_scac(carrier_scac).blank?
                             Carrier.create(name: carrier_name.titleize, scac: carrier_scac.upcase)
                           else
                             Carrier.find_by_scac(carrier_scac)
                           end
      end

      rate.assign_attributes(
        breakdown:,
        cost:,
        interstellar_service_type: interstellar_rate.service_name.to_s,
        reference: interstellar_rate.estimate_reference,
        tracking_carrier:,
        transit_days: interstellar_rate.transit_days
      )

      @rates << rate
    end

    nil
  end

  def fetch_pricing_rule_rates
    return unless @broker_carrier.pricing_rules.any?

    from_locations = Location
                     .where(zip_code: @shipment.shipper_address.zip_code)
                     .or(
                       Location.where(region: @shipment.shipper_address.region, zip_code: nil)
                     )
    to_locations = Location
                   .where(zip_code: @shipment.receiver_address.zip_code)
                   .or(
                     Location.where(region: @shipment.receiver_address.region, zip_code: nil)
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
    end

    nil
  end

  def build_rate(source)
    Rate.new(
      accessorials: combined_accessorials,
      broker_carrier: @broker_carrier,
      broker_customer: @shipment.broker_customer,
      shipment_fingerprint: @shipment.fingerprint,
      shipment: @shipment,
      source:,
      with_calculated_freight_classes: !@use_forced_freight_classes
    )
  end

  def packages
    @packages ||= @shipment.items.map do |i|
      i.as_interstellar_package(use_forced_freight_class: @use_forced_freight_classes)
    end
  end

  def pickup_at
    return @shipment.pickup_from unless @shipment.pickup_from.blank?

    DateTime.current.in_time_zone(@shipment.shipper_address.time_zone) + 3.hours
  end

  def accessorials
    return @accessorials if @accessorials

    @accessorials = []
    combined_accessorials.where.not(interstellar_code: [nil, '']).find_each do |accessorial|
      @accessorials << accessorial.interstellar_code.to_sym
    end

    @accessorials
  end

  def items
    @items ||= @shipment.items
  end
end
