# frozen_string_literal: true

module TransponderService
  module Input
    class Tariff < Base
      def build
        { overlength_rules: }
      end

      private

      def overlength_rules
        object.overlength_rules.where(cost_cents: (1..)).map { |overlength_rule| OverlengthRule.call(overlength_rule) }
      end
    end
  end
end
