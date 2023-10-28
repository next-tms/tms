# frozen_string_literal: true

module TransponderService
  module Input
    class Dimensions < Base
      def build
        {
          height: { amount: object.h, unit: 'in' },
          length: { amount: object.l, unit: 'in' },
          width: { amount: object.w, unit: 'in' }
        }
      end
    end
  end
end
