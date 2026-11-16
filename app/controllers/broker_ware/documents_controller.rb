class BrokerWare::DocumentsController < BrokerWare::ApplicationController
  URL_EXPIRES_IN = 5.minutes

  helper_method :names?

  def index
    shipment = authorized_scope(Shipment.all).find_by!(load_id: params[:loadid].presence || params.require(:load_id))
    authorize!(shipment, to: :view?)

    @documents = shipment.document_attachments.includes(:blob).select { |attachment| allowed_to?(:view?, attachment, with: DocumentPolicy) }
    @documents = @documents.select { |attachment| BrokerWare.document_name(attachment) }.sort_by(&:created_at)

    stale?(shipment, *@documents)
  end

  private

  def names? = params[:names].present?
end
