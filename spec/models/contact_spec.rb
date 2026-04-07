# frozen_string_literal: true

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
end
