# Provides access to broker's Stripe API
class Shipment::FetchAndCreateRatesService
  attr_accessor :shipment,
                :use_forced_freight_classes,
                :user_type,
                :rates_forced_freight_true,
                :rates_forced_freight_false,
                :populate_rate_jobs_on_queue

  delegate :calculated_freight_classes, :forced_freight_classes, to: :shipment

  def initialize(shipment:, user_id:, user_type: :broker)
    @shipment = shipment
    @user_id = user_id
    @user_type = user_type
    @rates_forced_freight_false = []
    @rates_forced_freight_true = []
    @populate_rate_jobs_on_queue = false
  end

  def call
    build_shipment_forced_freight_classes

    @use_forced_freight_classes.each do |use_forced_freight_class|
      existing_rates = []
      broker_carrier_with_no_rate_ids = []

      shipment.valid_broker_carriers_for_quotation(user_type: user_type).each do |broker_carrier|
        rates = Rate.by_shipment_and_broker_carrier(shipment, broker_carrier, use_forced_freight_class)
        if rates.present?
          existing_rates << rates
        else
          broker_carrier_with_no_rate_ids << broker_carrier.id
        end
      end

      instance_variable_set(
        "@rates_forced_freight_#{use_forced_freight_class}",
        existing_rates.flatten.uniq.sort_by { |r| r.cost_cents }
      )
      next unless broker_carrier_with_no_rate_ids.present?

      @populate_rate_jobs_on_queue = true
      PopulateRatesJob.perform_later(shipment.id, @user_id, use_forced_freight_class, broker_carrier_with_no_rate_ids)
    end

    return self
  end

  def build_shipment_forced_freight_classes
    if user_type == :broker
      return @use_forced_freight_classes = [false] if calculated_freight_classes.sort == forced_freight_classes.sort

      @use_forced_freight_classes = []
      @use_forced_freight_classes << false unless shipment.calculated_freight_classes == [nil]
      @use_forced_freight_classes << true unless shipment.forced_freight_classes == [nil]
    else
      @use_forced_freight_classes = [false] if forced_freight_classes.compact.sort == calculated_freight_classes.compact.sort
        
      @use_forced_freight_classes = [!@shipment.broker_customer.always_show_quotes_based_on_calculated_classes?]
    end
  end
end
