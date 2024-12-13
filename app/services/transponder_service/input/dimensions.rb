# frozen_string_literal: true

module TransponderService
  module Input
    class Dimensions < Base
      def build
        { height:, length:, width: }
      end

      private

      def height
        amount = object.h || 0

        { amount:, unit: 'in' }
      end

      def length
        amount = object.l || 0

        { amount:, unit: 'in' }
      end

      def width
        amount = object.w || 0

        { amount:, unit: 'in' }
      end
    end
  end
end
