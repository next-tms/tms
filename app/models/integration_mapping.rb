# == Schema Information
#
# Table name: integration_mappings
#
# @!attribute id
#   @return []
# @!attribute record_type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute external_id
#   @return [String]
# @!attribute integration_id
#   @return []
# @!attribute record_id
#   @return []
#
# Indexes
#
#  index_integration_mappings_on_integration_id  (integration_id)
#  index_integration_mappings_uniqueness         (record_type,record_id,integration_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (integration_id => integrations.id)
#
class IntegrationMapping < ApplicationRecord
  belongs_to :integration
  belongs_to :record, polymorphic: true

  validates :external_id, presence: true
  validates :record_id, uniqueness: { scope: %i[record_type integration_id] }
end
