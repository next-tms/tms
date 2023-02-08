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
#  index_contacts_on_companyable  (companyable_type,companyable_id)
#

require 'rails_helper'

RSpec.describe(Contact, type: :model) do
  it_behaves_like 'has_companyable'

  describe 'relationships' do
    it { is_expected.to(have_many(:document_preferences)) }
    it { is_expected.to(have_one(:user).dependent(:restrict_with_error)) }
    it { is_expected.to(belong_to(:companyable)) }
  end
end
