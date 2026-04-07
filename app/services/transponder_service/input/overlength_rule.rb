module TransponderService
  module Input
    class OverlengthRule < Base
      def build
        {
          cost: {
            currency: object.cost.currency.iso_code,
            fractional: object.cost.fractional
          },
          maximum_length:,
          minimum_length: { amount: object.min_length, unit: 'in' }
        }
      end

      private

      def maximum_length
        return if object.max_length.blank?

        { amount: object.max_length, unit: 'in' }
      end
    end
  end
end
