# == Schema Information
#
# Table name: contact_roles
#
# @!attribute id
#   @return []
# @!attribute role
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute contact_id
#   @return []
#
# Indexes
#
#  index_contact_roles_on_contact_id           (contact_id)
#  index_contact_roles_on_contact_id_and_role  (contact_id,role) UNIQUE
#  index_contact_roles_on_role                 (role)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#
# @!attribute id
#   @return []
# @!attribute role
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute contact_id
#   @return []
#
# Indexes
#
#  index_contact_roles_on_contact_id           (contact_id)
#  index_contact_roles_on_contact_id_and_role  (contact_id,role) UNIQUE
#  index_contact_roles_on_role                 (role)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#
class ContactRole < ApplicationRecord
  belongs_to :contact

  enum :role, {
    accounting: 'accounting',
    accounts_payable: 'accounts_payable',
    accounts_receivable: 'accounts_receivable',
    appointments: 'appointments',
    carrier_relations: 'carrier_relations',
    claims: 'claims',
    controller: 'controller',
    dispatch: 'dispatch',
    quoting: 'quoting',
    root: 'root',
    sales_rep_for_all_broker_customers: 'sales_rep_for_all_broker_customers',
    sales_rep: 'sales_rep',
    tracking: 'tracking'
  }

  validates :role, presence: true, uniqueness: { scope: :contact }

  def role
    super&.to_sym
  end
end
