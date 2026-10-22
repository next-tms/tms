# == Schema Information
#
# Table name: contacts
#
# @!attribute id
#   @return []
# @!attribute comments
#   @return [String]
# @!attribute companyable_type
#   @return [String]
# @!attribute email
#   @return [String]
# @!attribute first_name
#   @return [String]
# @!attribute job_title
#   @return [String]
# @!attribute label
#   @return [String]
# @!attribute last_name
#   @return [String]
# @!attribute mobile_phone
#   @return [String]
# @!attribute work_phone
#   @return [String]
# @!attribute companyable_id
#   @return []
#
# Indexes
#
#  idx_on_companyable_id_companyable_type_email_1de3a153e6  (companyable_id,companyable_type,email) UNIQUE
#  index_contacts_on_companyable                            (companyable_type,companyable_id)
#

require 'rails_helper'

RSpec.describe(Contact) do
  describe 'relationships' do
    it { is_expected.to(have_many(:contact_roles)) }
    it { is_expected.to(have_many(:document_preferences)) }
  end

  describe '#role?' do
    subject { contact.role?(role) }

    let(:broker_customer) { create(:broker_customer) }
    let(:contact) { create(:contact, companyable: broker_customer) }
    let(:role) { 'accounts_payable' }

    it { is_expected.to(be(false)) }

    context 'when the receivables contact' do
      let(:contact) { create(:contact, broker_customer_as_receivables_contact: broker_customer, companyable: broker_customer) }

      it { is_expected.to(be(true)) }

      context 'with a symbol' do
        let(:role) { :accounts_payable }

        it { is_expected.to(be(true)) }
      end
    end
  end

  describe 'unique email index' do
    before { create(:contact, companyable: nil, email: 'staff@acme.test') }

    it { expect { described_class.insert_all!([ { email: 'staff@acme.test' } ]) }.to(raise_error(ActiveRecord::RecordNotUnique)) }
    it { expect { described_class.insert_all!([ { email: nil }, { email: nil } ]) }.not_to(raise_error) }
  end
end
