# frozen_string_literal: true

module TransponderService
  module Input
    class Weight < Base
      def build
        {
          amount: object.weight,
          unit: 'lb'
        }
      end
    end
  end
end
