# frozen_string_literal: true

class FreightKitProService
  class << self
    # Fetch PRO (Progressive Rotating Order) from FreightKit API and update shipment accordingly
    def call(shipment:)
      return if shipment.pickup_confirmation.blank?

      pro = TransponderService.new(shipment:).fetch_pro
      # Multiple conditionals for pickup_on and dispatched_at presence are already handle in the Transponder
      return if pro.blank?

      shipment.update(pro:, updated_by: nil)
    end
  end
end
