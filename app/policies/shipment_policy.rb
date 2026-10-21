class ShipmentPolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[broker_notes carrier_cost carrier_cost_cents carrier_cost_currency tracking_carrier_pro]
  BROKER_METHODS = %i[total_cost]
  CUSTOMER_ATTRIBUTES = %i[
                          bol
                          bol_notes
                          created_at
                          customer_reference
                          delivered_at
                          load_id
                          picked_up_at
                          pro
                          receiver_contact_name
                          receiver_name
                          shipper_contact_name
                          shipper_name
                          shipper_reference
                          status
                          updated_at
                        ]
  CUSTOMER_METHODS = %i[
                       accessorial_list
                       average_density
                       calculated_freight_class_list
                       carrier_name
                       delivery_date
                       freight_class_list
                       item_description_list
                       item_summaries
                       loose_pieces_count
                       palletized_count
                       pickup_date
                       receiver_state
                       shipper_state
                       total_charges
                       total_item_weight
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
