class CarrierPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if broker?
    next relation.where(id: companyable.carrier_id) if carrier?

    relation.none
  end

  def view? = broker? || (carrier? && record == companyable.carrier)
end
