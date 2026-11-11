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
require 'rails_helper'

RSpec.describe(ContactRole) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:contact)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_presence_of(:role)) }
  end

  describe '#role' do
    context 'when super is nil' do
      let(:record) { build(:contact_role, role: nil) }

      it { expect(record.role).to(be_nil) }
    end

    context 'when super is not nil' do
      let(:record) { build(:contact_role) }

      it { expect(record.role).not_to(be_nil) }
    end
  end
end
