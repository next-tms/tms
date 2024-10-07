class BrokerCarrierPolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[
                        account
                        account_desc
                        accounting_notes
                        accounting_vendor_id
                        create_invoice_on_pickup
                        days_to_pay_after_invoice_date
                        default_bol_notes
                        ignore_bol_requires_tracking_number
                        quote_padding
                        shipments_count
                      ]
  CUSTOMER_ATTRIBUTES = %i[name]

  include AuthorizedAttributablePolicy

  def manage?
    return false unless broker?

    admin? || any_role?(:accounts_payable, :carrier_relations)
  end

  def view? = true
end
