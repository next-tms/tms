class BrokerCarrierPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if broker?
    next relation.where(id: companyable) if carrier?

    relation.none
  end

  def view? = broker? || (carrier? && record == companyable)
  def view_internal_notes? = broker?
  def view_markup? = broker?
end
