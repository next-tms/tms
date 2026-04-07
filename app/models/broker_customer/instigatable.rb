module BrokerCustomer::Instigatable
  extend ActiveSupport::Concern

  included do
    SUPPRESSOR_MAPPINGS = {
      requires_carrier_bol_on_receivables: {
        problematic_rule_code: 'missing_carrier_bol',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      },
      requires_carrier_pod_on_receivables: {
        problematic_rule_code: 'missing_carrier_pod',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      },
      requires_charges_confirmed_on_receivables: {
        problematic_rule_code: 'missing_charges_confirmed',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      },
      requires_customer_reference_number_on_receivables: {
        problematic_rule_code: 'missing_customer_reference',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      },
      requires_shipment_delivery_before_receivable: {
        problematic_rule_code: 'missing_delivery_at',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      },
      requires_shipment_shipper_reference_on_receivables: {
        problematic_rule_code: 'missing_shipper_reference',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      }
    }.freeze
  end
end
