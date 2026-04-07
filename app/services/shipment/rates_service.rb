# frozen_string_literal: true

class Shipment::RatesService
  SERVICE_CLASSES = [ FromPricingRules, FromTransponderService ]

  class << self
    def call(*args, **kwargs)
      SERVICE_CLASSES
      .map { |service_class| service_class.new(*args, **kwargs).call }
      .flatten
    end
  end
end
