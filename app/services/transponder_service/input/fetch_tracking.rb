# frozen_string_literal: true

module TransponderService
  module Input
    class FetchTracking < Base
      def build
        { tracking_number: }
      end

      private

      def tracking_number
        object.pro
      end
    end
  end
end
