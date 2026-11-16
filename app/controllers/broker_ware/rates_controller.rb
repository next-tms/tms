class BrokerWare::RatesController < BrokerWare::ApplicationController
  helper_method :breakdown?

  wrap_parameters :rating, format: :json, include: BrokerWare::Quote::ROOT_KEYS

  def create
    @shipment = Shipment.new(broker_customer:, quote_only: true)
    authorize!(@shipment, to: :create?)

    quote = BrokerWare::Quote.new(params.expect(rating: BrokerWare::Quote::PERMITTED), broker_customer:)

    unless quote.valid?
      render_error(quote.errors.full_messages.to_sentence, status: :bad_request)
      return
    end

    @shipment.assign_attributes(quote.shipment_attributes)
    @shipment.created_by = current_user
    @shipment.updated_by = current_user

    unless @shipment.save
      render_error(@shipment.errors.full_messages.to_sentence, status: :bad_request)
      return
    end

    @rates = Shipment::QuotableRatesService.call(@shipment, declared_freight_classes: quote.declared_freight_classes?, user_type: :customer)
  end

  private

  def breakdown? = params[:breakdown].present?
end
