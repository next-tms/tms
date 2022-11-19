# frozen_string_literal: true

module Broker::Instigatable
  extend ActiveSupport::Concern

  included do
    SUPPRESSOR_MAPPINGS = {
      requires_charges_confirmed_on_receivables: {
        problematic_rule_code: 'missing_charges_confirmed',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable',
      }
    }.freeze
  end
end
