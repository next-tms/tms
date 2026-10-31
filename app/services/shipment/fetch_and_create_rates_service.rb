# Provides access to broker's Stripe API
class Shipment::FetchAndCreateRatesService
  class << self
    def call(shipment, user_type:, shipment_fingerprint:)
      new(shipment, user_type:, shipment_fingerprint:).call
    end
  end

  attr_accessor :populate_rate_jobs_on_queue
  attr_reader :rates_declared_freight_classes_false,
              :rates_declared_freight_classes_true,
              :shipment,
              :shipment_fingerprint,
              :user_type

  def initialize(shipment, shipment_fingerprint:, user_type:)
    raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(Shipment)
    raise ArgumentError, 'shipment_fingerprint cannot be blank' if shipment_fingerprint.blank?
    raise ArgumentError, 'user_type must be one of :broker, :customer' if %i[broker customer].exclude?(user_type)

    @populate_rate_jobs_on_queue = false
    @rates_declared_freight_classes_false = []
    @rates_declared_freight_classes_true = []
    @shipment = shipment
    @shipment_fingerprint = shipment_fingerprint
    @user_type = user_type
  end

  # @return [Shipment::FetchAndCreateShipment::RatesService]
  def call
    declared_freight_classes.each do |declared_freight_classes|
      existing_rates = []
      broker_carrier_without_rate_ids = []

      broker_carriers.each do |broker_carrier|
        rate = Rate.find_by(
          broker_carrier:,
          declared_freight_classes:,
          shipment_fingerprint:,
          shipment:
        )

        if rate.present?
          existing_rates << rate
          next
        end

        broker_carrier_without_rate_ids << broker_carrier.id
      end

      instance_variable_set(
        "@rates_declared_freight_classes_#{declared_freight_classes}",
        existing_rates.uniq.sort_by(&:cost_cents)
      )

      next if broker_carrier_without_rate_ids.empty?

      @populate_rate_jobs_on_queue = true

      Shipment::CreateRatesJob.perform_later(
        shipment,
        shipment_fingerprint,
        user_type,
        declared_freight_classes,
        broker_carrier_without_rate_ids
      )
    end

    self
  end

  # @return [Array<Boolean>]
  def declared_freight_classes
    return [false] if shipment.calculated_freight_classes.sort == shipment.declared_freight_classes.sort

    if user_type == :broker
      return [].tap do |builder|
               builder << false if shipment.calculated_freight_classes.compact.any?
               builder << true if shipment.declared_freight_classes.compact.any?
             end
    end

    [!@shipment.broker_customer.always_show_quotes_based_on_calculated_classes?]
  end

  private

  def broker_carriers
    shipment.valid_broker_carriers_for_quotation(user_type)
  end
end
