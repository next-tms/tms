# frozen_string_literal: true

module TransponderService
  module Input
    class Money < Base
      def build
        {
          currency: object.currency.iso_code,
          fractional: object.fractional
        }
      end
    end
  end
end
