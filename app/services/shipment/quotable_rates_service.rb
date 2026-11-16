class Shipment::QuotableRatesService
  class << self
    def call(shipment, user_type:, declared_freight_classes: false, broker_carrier_id: nil)
      new(shipment, broker_carrier_id:, declared_freight_classes:, user_type:).call
    end

    def quotable?(rate, user_type:)
      return false unless rate.cost_cents.to_i.positive?
      return true if user_type == :broker

      rate.charge.present? && rate.charge > rate.cost
    end
  end

  attr_reader :broker_carrier_id, :declared_freight_classes, :shipment, :user_type

  def initialize(shipment, broker_carrier_id:, declared_freight_classes:, user_type:)
    @broker_carrier_id = broker_carrier_id
    @declared_freight_classes = declared_freight_classes
    @shipment = shipment
    @user_type = user_type
  end

  def call
    rates = broker_carriers.flat_map { |broker_carrier| broker_carrier_rates(broker_carrier) }

    rates.select { |rate| self.class.quotable?(rate, user_type:) }.sort_by(&:cost_cents)
  end

  private

  def broker_carrier_rates(broker_carrier)
    rates = Rate.where(broker_carrier:, declared_freight_classes:, shipment:, shipment_fingerprint: shipment.fingerprint)
    rates = rates.where(expires_at: nil).or(rates.where(expires_at: Time.current..)).to_a
    return rates if rates.any?

    Shipment::RatesService.call(broker_carrier, shipment, declared_freight_classes:, save: true)
  end

  def broker_carriers
    broker_carriers = shipment.valid_broker_carriers_for_quotation(user_type)
    broker_carrier_id ? broker_carriers.where(id: broker_carrier_id) : broker_carriers
  end
end
