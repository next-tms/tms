# == Schema Information
#
# Table name: audits
#
# @!attribute id
#   @return []
# @!attribute action
#   @return [String]
# @!attribute associated_type
#   @return [String]
# @!attribute auditable_type
#   @return [String]
# @!attribute audited_changes
#   @return [Hash]
# @!attribute comment
#   @return [String]
# @!attribute remote_address
#   @return [String]
# @!attribute request_uuid
#   @return [String]
# @!attribute user_type
#   @return [String]
# @!attribute username
#   @return [String]
# @!attribute version
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute associated_id
#   @return [Integer]
# @!attribute auditable_id
#   @return [Integer]
# @!attribute user_id
#   @return [Integer]
#
# Indexes
#
#  associated_index              (associated_type,associated_id)
#  auditable_index               (auditable_type,auditable_id,version)
#  index_audits_on_created_at    (created_at)
#  index_audits_on_request_uuid  (request_uuid)
#  user_index                    (user_id,user_type)
#
require 'rails_helper'

RSpec.describe(Audit) do
  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(eq(['action', 'auditable_id', 'created_at'])) }
  end
end
