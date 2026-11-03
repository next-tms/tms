class SyncTransponderCarriersJob < ApplicationJob
  def perform
    Transponder::ORM::Carrier.all.each do |transponder_carrier| # rubocop:disable Rails/FindEach
      carrier = Carrier.find_by(transponder_id: transponder_carrier.id) ||
                Carrier.where.not(scac: nil).find_by(scac: transponder_carrier.scac, transponder_id: nil)
      sync(carrier, transponder_carrier) if carrier.present?
    end
  end

  private

  def sync(carrier, transponder_carrier)
    carrier.update(
      acts_as_broker: transponder_carrier.acts_as_broker?,
      consider_bol_and_pod_documents_same: transponder_carrier.consider_bol_and_pod_documents_same?,
      legal_name: transponder_carrier.legal_name,
      name: transponder_carrier.name,
      scac: transponder_carrier.scac,
      transponder_id: transponder_carrier.id
    ) || Sentry.capture_message("Carrier #{carrier.id} not synced: #{carrier.errors.full_messages.to_sentence}")
  end
end
