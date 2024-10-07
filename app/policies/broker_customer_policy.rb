class BrokerCustomerPolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[
                        always_show_quotes_based_on_calculated_classes
                        can_quote
                        default_bol_notes
                        default_upcharge
                        default_upcharge_percentage
                        enable_auto_freight_class
                        ignore_value_on_api_quotes
                        internal_notes
                      ]
  CUSTOMER_ATTRIBUTES = %i[
                          name
                          receivables_schedule
                          requires_carrier_bol_on_receivables
                          requires_carrier_pod_on_receivables
                          requires_charges_confirmed_on_receivables
                          requires_customer_reference_number_on_receivables
                          requires_shipment_delivery_before_receivable
                          requires_shipment_shipper_reference_on_receivables
                        ]

  include AuthorizedAttributablePolicy
end
