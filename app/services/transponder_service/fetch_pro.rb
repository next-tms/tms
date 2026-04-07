module TransponderService
  class FetchPro
    class << self
      # @return [Boolean]
      def call(shipment)
        raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(Shipment)

        return false if shipment.pickup_confirmation.blank?

        pro = TransponderService.query(:fetch_pro, shipment.broker_carrier, shipment)[:value]
        return false if pro.blank?

        shipment.update!(pro:, updated_by: nil)
        shipment.problematic!

        true
      end
    end
  end
end
