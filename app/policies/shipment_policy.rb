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

  BROKER_ATTRIBUTES.each do |attribute|
    define_method("#{attribute}_attribute?") do
      broker?
    end
  end

  CUSTOMER_ATTRIBUTES.each do |attribute|
    define_method("#{attribute}_attribute?") do
      customer? || broker?
    end
  end

  def show?
    return false unless record

    record.accessible_by?(user)
  end
end
