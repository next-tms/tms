class DSDC::DocumentsController < DSDC::CarrierController
  MAX_RESPONSE_SIZE = 100.megabytes

  before_action :set_payment_transaction, only: %i[destroy show]

  def create
    document = DSDC::DocumentPayload.new(request.request_parameters)
    payment_transaction = @payment_transactions.where(dsdc_unique_id: document.unique_id, invoice: document.invoice_number).sole
    authorize!(payment_transaction, to: :manage?)

    payment_transaction.attach_dsdc_documents(document.attachables)

    render('dsdc/carrier/success', locals: { message: t('.message') }, status: :created)
  end

  def destroy
    authorize!(@payment_transaction, to: :manage?)

    attachments = @payment_transaction.dsdc_documents_attachments
    attachments = attachments.where(id: params[:fileIds]) if params[:fileIds].present?
    attachments.destroy_all

    head(:no_content)
  end

  def index
    attachments = ActiveStorage::Attachment.preload(:blob, :record).where(name: 'dsdc_documents', record: @payment_transactions)
    if params[:documentType].present?
      attachments = attachments.joins(:blob).where("active_storage_blobs.metadata::jsonb ->> 'document_type' IN (?)", params[:documentType])
    end

    if too_large?(attachments)
      render_business_error
      return
    end

    @documents = attachments.group_by(&:record)

    stale?(*@documents.keys)
  end

  def show
    authorize!(@payment_transaction, to: :view?)

    @documents = @payment_transaction.dsdc_documents_attachments.includes(:blob)

    if too_large?(@documents)
      render_business_error
      return
    end

    stale?(@payment_transaction)
  end

  private

  def set_payment_transaction = @payment_transaction = @payment_transactions.where(invoice: params[:invoice_number]).sole
  def too_large?(attachments) = attachments.joins(:blob).sum('active_storage_blobs.byte_size') > MAX_RESPONSE_SIZE
end
