class Shipment::RatesService
  SERVICE_CLASSES = [FromPricingRules, FromTransponderService].freeze

  class << self
    def call(*, **)
      SERVICE_CLASSES
        .map { |service_class| service_class.new(*, **).call }
        .flatten
    end
  end
end
