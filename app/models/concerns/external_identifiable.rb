module ExternalIdentifiable
  extend ActiveSupport::Concern

  included { has_many :integration_mappings, as: :record, dependent: :destroy }

  def external_id_for(integration) = integration_mappings.find_by(integration:)&.external_id

  def store_external_id(integration, external_id)
    integration_mappings.find_or_initialize_by(integration:).update!(external_id:)
    external_id
  end
end
