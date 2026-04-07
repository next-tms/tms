module ProblematicService
  class Processor::Shipment < Processor::Base
    class << self
      def model
        Shipment
      end
    end
  end
end
