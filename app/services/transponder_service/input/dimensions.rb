# frozen_string_literal: true

module TransponderService
  module Input
    class Dimensions < Base
      def build
        return if [object.h, object.l, object.w].any?(&:blank?)

        { height:, length:, width: }
      end

      private

      def height
        return if object.h.blank?

        { amount: object.h, unit: 'in' }
      end

      def length
        return if object.l.blank?

        { amount: object.l, unit: 'in' }
      end

      def width
        return if object.w.blank?

        { amount: object.w, unit: 'in' }
      end
    end
  end
end
