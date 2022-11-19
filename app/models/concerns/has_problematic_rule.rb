# frozen_string_literal: true

module HasProblematicRule
  extend ActiveSupport::Concern

  included do
    validates :problematic_rule_code, presence: true
  
    validate :validate_problematic_rule_code

    def problematic_rule
      problematic_type
      .constantize
      .problematic_processor
      .rules
      .find { |problematic_rule|  problematic_rule.code == problematic_rule_code }
    end

    private

    def validate_problematic_rule_code
      return unless new_record? &&
                    problematic_rule_code.present? &&
                    problematic_type.present?
                    
      return if problematic_type
               .constantize
               .problematic_rule_codes
               .any?(problematic_rule_code.to_sym)
  
      errors.add(
        :problematic_rule_code,
        "must be one of #{problematic_type.constantize.problematic_rule_codes.join(', ')}, got #{problematic_rule_code}"
      )
    end
  end
end
