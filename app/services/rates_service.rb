# frozen_string_literal: true

class RatesService
  def initialize(broker_carrier:, shipment:, use_forced_freight_classes:)
    @broker_carrier = broker_carrier
    @shipment = shipment
    @use_forced_freight_classes = use_forced_freight_classes
  end

  def to_rates
    calculated_freight_classes = items.map(&:calculated_freight_class)
    forced_freight_classes = items.map(&:forced_freight_class)

    return [] if calculated_freight_classes.blank? && forced_freight_classes.blank?

    unless @broker_carrier.pricing_rules.blank?
      @broker_carrier
        .pricing_rules
        .where('min_pallets <= ?', @shipment.flattened_items.size)
        .where('max_pallets >= ?', @shipment.flattened_items.size)
        .find_each do |pricing_rule|
        unless pricing_rule.carrier_area.from_area.zip_codes.include?(@shipment.shipper_address.zip_code) &&
               pricing_rule.carrier_area.to_area.zip_codes.include?(@shipment.receiver_address.zip_code)
          next
        end

        cost = Money.new(pricing_rule.cost_per_pallet * @shipment.flattened_items.size)
        cost += @broker_carrier.quote_padding unless @broker_carrier.quote_padding.blank?

        rate = new_rate
        rate.assign_attributes(cost:)

        return [rate]
      end
    end

    return [] if @broker_carrier.as_interstellar_carrier.blank?

    response = nil
    error = nil

    if !@shipment.broker_customer.ignore_value_on_api_quotes? && !@shipment.value.zero? && !@broker_carrier.as_interstellar_carrier.find_rates_with_declared_value?
      error = StandardError.new('Carrier doesn’t support quoting with declared value')

      rate = new_rate
      rate.assign_attributes(error_object: error)

      return [rate]
    end

    api_shipment = Interstellar::Shipment.new(
      accessorials:,
      declared_value_cents: @shipment.value_cents,
      origin: @shipment.shipper_address.to_interstellar_shipping_address,
      destination: @shipment.receiver_address.to_interstellar_shipping_address,
      packages:
    )

    begin
      response = InterstellarApiClient.fetch_rates(
        broker_carrier: @broker_carrier,
        shipment: api_shipment
      )
    rescue StandardError => e
      error = e
    end

    if response.blank? || response&.rates.blank?
      rate = new_rate
      rate.assign_attributes(error_object: error)

      return [rate]
    end

    rates = []

    interstellar_rates = response.rates
    interstellar_rates.each do |interstellar_rate|
      cost = Money.new(interstellar_rate.price)

      unless cost.positive?
        rate = new_rate
        rate.assign_attributes(
          error_object: StandardError.new('Cost was empty'),
          request: response.request,
          response: response.params
        )

        rates << rate
        next
      end

      cost += @broker_carrier.quote_padding unless @broker_carrier.quote_padding.blank?

      tracking_carrier = nil
      if @broker_carrier.carrier.acts_as_broker?
        carrier_name = interstellar_rate.carrier[:name]
        carrier_scac = interstellar_rate.carrier[:scac]

        if carrier_scac.blank? || carrier_name.blank?
          rate = new_rate
          rate.assign_attributes(
            error_object: StandardError.new('Carrier (acting as broker) API returned quote with missing carrier name and SCAC'),
            request: response.request,
            response: response.params
          )

          rates << rate
          next
        end

        # Import carrier information
        tracking_carrier = if Carrier.find_by_scac(carrier_scac).blank?
                             Carrier.create(name: carrier_name.titleize, scac: carrier_scac.upcase)
                           else
                             Carrier.find_by_scac(carrier_scac)
                           end
      end

      rate = new_rate
      rate.assign_attributes(
        cost:,
        reference: interstellar_rate.estimate_reference,
        tracking_carrier:,
        transit_days: interstellar_rate.transit_days,
        interstellar_service_type: interstellar_rate.service_name.to_s,
        request: response.request,
        response: response.params
      )

      rates << rate
    end

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

  def new_rate
    Rate.new(
      accessorials: combined_accessorials,
      broker_carrier: @broker_carrier,
      broker_customer: @shipment.broker_customer,
      shipment_fingerprint: @shipment.fingerprint,
      shipment: @shipment,
      with_calculated_freight_classes: !@use_forced_freight_classes
    )
  end

  def packages
    @packages ||= @shipment.items.map do |i|
      i.as_interstellar_package(use_forced_freight_class: @use_forced_freight_classes)
    end
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
