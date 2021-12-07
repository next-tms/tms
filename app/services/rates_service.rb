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

    if calculated_freight_classes.blank? && forced_freight_classes.blank?
      rate = new_rate

      rate.assign_attributes(
        error: '@shipment#update_quotes: calculated_freight_classes and forced_freight_classes are blank'
      )

      return [rate]
    end

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
        rate.assign_attributes(cost: cost)

        return [rate]
      end
    end

    error = nil
    interstellar_error_class = nil
    response = nil

    begin
      response = InterstellarApiClient.fetch_rates(
        broker_carrier: @broker_carrier,
        origin: @shipment.shipper_address.to_interstellar_shipping_address,
        destination: @shipment.receiver_address.to_interstellar_shipping_address,
        packages: packages,
        accessorials: accessorials
      )
    rescue StandardError => e
      error = "API Error: #{e.class.name}: #{e.message}"
      interstellar_error_class = e.class.name
      response = nil

      case e.class
      when Interstellar::InvalidCredentialsError
        error = 'Invalid username/password'
      when Interstellar::UnserviceableError
        error = "No service (#{error})"
      end
    end

    if response.blank? || response.rates.blank?
      rate = new_rate
      rate.assign_attributes(error: error, interstellar_error_class: interstellar_error_class)

      return [rate]
    end

    rates = []

    interstellar_rates = response.rates
    interstellar_rates.each do |interstellar_rate|
      cost = Money.new(interstellar_rate.price)

      if cost == Money.new(0)
        rate = new_rate
        rate.assign_attributes(
          error: 'API Error: Cost was blank',
          request: response.request,
          response: response.params
        )

        rates << rate
        next
      end

      cost += @broker_carrier.quote_padding unless @broker_carrier.quote_padding.blank?

      dimensions = items.pluck(:l, :w).flatten
      dimensions_contain_blank = !dimensions.size == (dimensions - [nil, '']).size
      max_dimension = dimensions&.max || 48

      if !interstellar_rate.with_excessive_length_fees && (max_dimension > 48 || dimensions_contain_blank)
        if @broker_carrier.overlength_rules.blank?
          rate = new_rate
          rate.assign_attributes(
            error: 'API Error: Unable to quote overlength fees as they are tariff-based, broker has not defined tariff rules',
            request: response.request,
            response: response.params
          )

          rates << rate
          next
        end

        overlength_rule = @broker_carrier
                          .overlength_rules.where('min_length <= ?', max_dimension)
                          .where('max_length >= ?', max_dimension)
                          &.first

        if overlength_rule.blank?
          overlength_rule = @broker_carrier
                            .overlength_rules.where('min_length <= ?', max_dimension)
                            .where(max_length: nil)
                            &.first
        end

        cost += overlength_rule.cost unless overlength_rule.blank?
      end

      tracking_carrier = nil
      if @broker_carrier.carrier.acts_as_broker?
        carrier_name = interstellar_rate.carrier.dig(:name)
        carrier_scac = interstellar_rate.carrier.dig(:scac)

        if carrier_scac.blank? || carrier_name.blank?
          rate = new_rate
          rate.assign_attributes(
            error: 'API Error: Carrier (acting as broker) API returned quote with missing carrier name and SCAC',
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
        cost: cost,
        reference: interstellar_rate.estimate_reference,
        tracking_carrier: tracking_carrier,
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
    @packages ||= @shipment.items.map { |i| i.as_interstellar_package(use_forced_freight_class: @use_forced_freight_classes) }
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
