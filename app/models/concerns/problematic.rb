module Problematic
  extend ActiveSupport::Concern

  included do
    after_commit :problematic!

    has_many :problems, as: :resolvable
    has_many :suppressions, as: :problematic

    class << self
      def problematic_processor
        "ProblematicService::Processor::#{name}".constantize
      end

      def problematic_rules
        problematic_processor.rules
      end

      def problematic_rule_codes
        problematic_rules.map { |rule| rule.code.to_sym }
      end
    end

    def problematic!
      self.class.problematic_processor.call(self)
    end
  end
end
