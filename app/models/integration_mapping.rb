class IntegrationMapping < ApplicationRecord
  belongs_to :integration
  belongs_to :record, polymorphic: true

  validates :external_id, presence: true
  validates :record_id, uniqueness: { scope: %i[record_type integration_id] }
end
