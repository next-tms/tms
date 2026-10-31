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
FactoryBot.define { factory(:contact_role) { role { ContactRole.roles.keys.sample } } }
