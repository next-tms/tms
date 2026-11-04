class DSDC::InvoicesController < DSDC::CarrierController
  before_action :set_invoice, only: %i[create update]
  before_action :set_payment_transaction, only: %i[destroy show update]

  def create
    @payment_transaction = PaymentTransaction.new
    authorize!(@payment_transaction, to: :manage?)

    unless @invoice.mc_matches?(current_user.companyable.mc_number)
      render_errors('300')
      return
    end

    unless @payment_transaction.update(@invoice.payment_transaction_attributes(current_user.companyable))
      render_errors('300')
      return
    end

    render('dsdc/carrier/success', locals: { message: t('.message') })
  end

  def destroy
    authorize!(@payment_transaction, to: :manage?)

    @payment_transaction.with_lock do
      if @payment_transaction.payment.present?
        render_errors('500')
        return
      end

      @payment_transaction.destroy!
    end

    head(:no_content)
  end

  def index = stale?(@payment_transactions)

  def show
    authorize!(@payment_transaction, to: :view?)

    stale?(@payment_transaction)
  end

  def update
    authorize!(@payment_transaction, to: :manage?)

    if @invoice.unique_id != params[:unique_id]
      render_errors('400')
      return
    end

    unless @invoice.mc_matches?(current_user.companyable.mc_number)
      render_errors('300')
      return
    end

    @payment_transaction.with_lock do
      if @payment_transaction.payment.present?
        render_errors('500')
        return
      end

      unless @payment_transaction.update(@invoice.payment_transaction_attributes(current_user.companyable))
        render_errors('300')
        return
      end
    end

    render('dsdc/carrier/success', locals: { message: t('.message') })
  end

  private

  def set_invoice = @invoice = DSDC::InvoicePayload.new(request.request_parameters)
  def set_payment_transaction = @payment_transaction = @payment_transactions.where(dsdc_unique_id: params[:unique_id]).sole
end
