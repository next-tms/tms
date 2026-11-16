class BrokerWare::InvoicesController < BrokerWare::ApplicationController
  CUSTOM_FIELDS_PERIOD = 30.days
  INCLUDES = [
    :receivable_items,
    {
      shipment: [:items, :receiver_address, :shipper_address, { broker_customer: %i[customer office_address] }]
    }
  ].freeze

  helper_method :custom_fields?

  rescue_from Date::Error, with: :render_bad_request

  def index
    authorize!(Receivable, to: :index?)

    @receivables = authorized_scope(Receivable.unpaid.includes(INCLUDES)).order(:created_at)
    @receivables = @receivables.where(created_at: invoice_dates) if custom_fields?

    stale?(@receivables, ReceivableItem.where(receivable: @receivables), Setting.all)
  end

  private

  def custom_fields? = params[:custom_fields].present?

  def invoice_dates
    start_on = params[:start_date].present? ? BrokerWare.date(params[:start_date]) : CUSTOM_FIELDS_PERIOD.ago.to_date
    end_on = params[:end_date].present? ? BrokerWare.date(params[:end_date]) : Date.current

    start_on.beginning_of_day..end_on.end_of_day
  end
end
