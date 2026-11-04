class InvitationPolicy < ApplicationPolicy
  def create? = broker? && same_company_contact? && (authorizable.role?(:root) || carrier_invitation? || customer_invitation?)

  private

  def carrier_invitation? = record.carrier? && authorizable.role?(:accounts_payable)
  def customer_invitation? = record.customer? && authorizable.sales_rep_for?(record.companyable)
  def same_company_contact? = record.contact.nil? || record.contact.companyable == record.companyable
end
