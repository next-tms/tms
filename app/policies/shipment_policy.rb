class ShipmentPolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[
                        carrier_cost
                        carrier_cost_cents
                        carrier_cost_currency
                        tracking_carrier_pro
                      ]
  CUSTOMER_ATTRIBUTES = %i[
                          bol_notes
                          created_at
                          delivered_at
                          load_id
                          picked_up_at
                          pro
                          receiver_contact_name
                          receiver_name
                          shipper_contact_name
                          shipper_name
                          updated_at
                        ]

  include AuthorizedAttributablePolicy

  def manage?
    return broker_party? if broker?

    record_customer? && (any_role?(:root) || record.created_by == authorizable)
  end

  def party?
    return broker_party? if broker?

    record_customer? && record.created_by == authorizable
  end

  def view?
    return false unless record

    manage? || record.accessible_by?(authorizable)
  end

  private

  def broker_party?
    record.broker == authorizable.companyable &&
      (any_role?(:dispatch, :root, :sales_rep_for_all_broker_customers) || record.dispatcher == authorizable)
  end

  def record_customer? = customer? && record.broker_customer == authorizable.companyable
end
