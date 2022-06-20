# frozen_string_literal: true

class InterstellarProService
  class << self

    # Fetch PRO (Progressive Rotating Order) from Interstellar API and update shipment accordingly
    def call(shipment:)
      return nil if shipment.pickup_confirmation.blank?

      broker_carrier = shipment.broker_carrier
      pickup_number = shipment.pickup_confirmation
      pickup_on = shipment.pickup_on
      dispatched_at = shipment.dispatched_at

      pro = nil
      pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number:, date: pickup_on)

      if pro.blank? && dispatched_at.present?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number:, date: dispatched_at.to_date)
      end

      if pro.blank? && pickup_on.present?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number:, date: pickup_on - 1.day)
      end

      if pro.blank? && pickup_on.present?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number:, date: pickup_on + 1.day)
      end

      if pro.blank? && pickup_on.present?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number:, date: pickup_on + 2.days)
      end

      if pro.blank? && dispatched_at.present?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number:, date: dispatched_at.to_date + 1.day)
      end

      return if pro.blank?

      shipment.update(pro:, updated_by: nil)
    end
  end
end
