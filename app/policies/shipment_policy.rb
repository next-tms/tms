class ShipmentPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation.where(broker_carrier: companyable.broker_carriers) if carrier?

    relation.accessible_by(authorizable)
  end

  def create? = broker? || customer?
  def fetch_rates? = !carrier? && view?
  def index? = broker? || customer?
  def manage? = record.accessible_by?(authorizable)

  def view?
    return false unless record
    return record.broker_carrier&.carrier == companyable if carrier?

    manage?
  end

  def view_carrier_references? = !customer?
  def view_charges? = broker? || customer?
  def view_costs? = broker? || carrier?
  def view_internal_notes? = broker?
  def view_shared_notes? = broker? || customer?
end
