# frozen_string_literal: true

class Shipment::RatesService
  class FromTransponderService < Base
    EMPTY_COST_ERROR = StandardError.new('Cost was empty')
    MISSING_SCAC_ERROR = StandardError.new('Carrier (acting as broker) API returned quote with missing carrier name and SCAC')
    NO_RATES_ERROR = StandardError.new('No rates returned from API')
    DeclaredValueNotImplementedByCarrierError = StandardError.new('Carrier doesn’t support quoting shipments with declared value')

    def call
      return rates if broker_carrier.to_freight_kit_carrier.blank?

      response = nil

      if !ignore_value? && shipment.value.positive? && !carrier_finds_rate_with_declared_value?
        rate = build_rate(:api)

        rate.api_errors = [{ message: "#{Shipment.model_name.human} #{Shipment.human_attribute_name(:value).downcase} not supported" }]

        @rates << rate
        rate.save! if save?

        return rates
      end

      begin
        response = TransponderService
                   .query(
                     :fetch_rates,
                     broker_carrier,
                     shipment,
                     declared_freight_classes:,
                   )
      rescue StandardError => e
        Rails.env.development? ? raise(e) : Honeybadger.notify(e)

        return rates
      end

      return rates if response.blank?

      errors = response[:errors]

      if errors.any?
        rate = build_rate(:api)
        rate.assign_attributes(
          api_errors: errors,
          api_request: response[:request],
          api_response: response[:response],
        )

        @rates << rate
        rate.save! if save?

        return rates
      end

      transponder_rates = response[:rates]

      if transponder_rates.blank? || transponder_rates.try(:empty?)
        rate = build_rate(:api)

        errors = [{ message: "No #{Rate.model_name.human.downcase.pluralize} returned" }]

        rate.assign_attributes(
          api_errors: errors,
          api_request: response[:request],
          api_response: response[:response],
        )

        @rates << rate
        rate.save! if save?

        return rates
      end

      transponder_rates.map! do |transponder_rate|
        transponder_rate.deep_transform_keys! do |key|
          key.to_s.underscore.to_sym
        end
      end

      transponder_rates.each do |transponder_rate|
        rate = build_rate(:api)

        rate.assign_attributes(
          api_request: response[:request].try(:to_json),
          api_response: response[:response].try(:to_json),
        )

        currency = transponder_rate.dig(:total_cost, :currency)
        fractional = transponder_rate.dig(:total_cost, :fractional)

        if [currency, fractional].all?(&:present?)
          cost = Money.new(fractional, currency)
        else
          rate.errors = [{ message: 'No rates returned from the carrier' }]

          @rates << rate
          rate.save! if save?

          next
        end

        # cost += broker_carrier.quote_padding unless broker_carrier.quote_padding.blank?

        tracking_carrier = nil
        if broker_carrier.carrier.acts_as_broker?
          carrier_name = transponder_rate.dig(:shipping_carrier, :name)
          carrier_scac = transponder_rate.dig(:shipping_carrier, :scac)

          next if carrier_name.blank? || carrier_scac.blank?

          # Import carrier information
          tracking_carrier = Carrier.find_or_initialize_by(scac: carrier_scac.upcase)
          tracking_carrier.name ||= carrier_name.titleize
          tracking_carrier.save!
        end

        rate.assign_attributes(
          breakdown: transponder_rate[:costs],
          cost:,
          freight_kit_service_type: transponder_rate[:service_name],
          reference: transponder_rate[:estimate_reference],
          tracking_carrier:,
          transit_days: transponder_rate[:transit_days],
        )

        @rates << rate
        rate.save! if save?
      end

      rates
    end

    private

    def carrier_finds_rate_with_declared_value
      broker_carrier.to_freight_kit_carrier.class.find_rates_with_declared_value?
    end
  end
end
