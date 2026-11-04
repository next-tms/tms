module Mutations
  module Concerns
    module Shippable
      extend ActiveSupport::Concern

      private

      def actor = context[:authorizable]

      def broker_customer_for(broker_customer_id)
        authorizable = context[:authorizable]
        return authorizable.companyable if authorizable.customer?
        return unless authorizable.broker?

        authorizable.broker_customers.find_by(id: broker_customer_id)
      end

      def raise_error(message, code) = raise(GraphQL::ExecutionError.new(message, extensions: { code: }))

      def raise_record_errors(record)
        raise(GraphQL::ExecutionError.new(record.errors.full_messages.to_sentence, extensions: record.errors.to_hash))
      end

      def raise_unserviceable_accessorials(accessorial_codes)
        message = "Accessorials not offered: #{accessorial_codes.join(', ')}"
        raise(GraphQL::ExecutionError.new(message, extensions: { accessorialCodes: accessorial_codes, code: 'UNSERVICEABLE_ACCESSORIALS' }))
      end

      def shipment_broker_accessorials_attributes(shipment, accessorial_codes)
        broker_accessorials = shipment
                              .broker_customer
                              .eligible_broker_accessorials
                              .joins(:accessorial)
                              .where(accessorial: { freight_kit_code: accessorial_codes })
        unserviceable_codes = accessorial_codes.uniq - broker_accessorials.pluck('accessorials.freight_kit_code')
        raise_unserviceable_accessorials(unserviceable_codes) if unserviceable_codes.any?

        broker_accessorials.ids.map { |broker_accessorial_id| { broker_accessorial_id: } }
      end
    end
  end
end
