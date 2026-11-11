# == Schema Information
#
# Table name: integrations
#
# @!attribute id
#   @return []
# @!attribute credentials
#   @return [Hash]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_integrations_on_kind_and_name  (kind,name) UNIQUE
#
# @!attribute id
#   @return []
# @!attribute credentials
#   @return [Hash]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_integrations_on_kind_and_name  (kind,name) UNIQUE
#
require 'rails_helper'

RSpec.describe Integration do
  subject(:record) { build(:integration) }

  describe 'only one connected accounting integration' do
    let!(:other_record) { create(:integration) }

    it { is_expected.not_to be_valid }
    it { expect(record.tap(&:valid?).errors[:base]).to include('another accounting integration is already connected') }
  end
end
