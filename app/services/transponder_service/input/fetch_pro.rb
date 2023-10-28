# frozen_string_literal: true

module TransponderService
  module Input
    class FetchPro < Base
      def build
        { dispatched_on:, picked_up_on:, pickup_number: }
      end

      private

      def dispatched_on
        object.dispatched_at.to_date.iso8601
      end

      def picked_up_on
        (object.picked_up_at&.to_date.presence || object.pickup_on).iso8601
      end

      def pickup_number
        object.pickup_confirmation
      end
    end
  end
end
