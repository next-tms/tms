class Freightview::LTLShipmentsController < Freightview::ApplicationController
  wrap_parameters :shipment, format: :json, include: Freightview::LTLShipmentPayload::ROOT_KEYS

  def create
    @shipment = Shipment.new(broker_customer: (current_user.companyable if current_user.customer?), quote_only: true)
    authorize!(@shipment, to: :create?)

    if @shipment.broker_customer.blank?
      render_error('ForbiddenError', t('.customer_required'), status: :forbidden)
      return
    end

    @payload = Freightview::LTLShipmentPayload.new(Freightview.decode_keys(shipment_params))
    errors = accessorial_errors

    if errors.any?
      render_error('ValidationError', t('.unsupported_accessorials'), errors:, status: :bad_request)
      return
    end

    @shipment.assign_attributes(**@payload.shipment_attributes, shipment_accessorials_attributes:)
    @shipment.created_by = current_user
    @shipment.updated_by = current_user

    unless @shipment.save
      render_record_errors(@shipment)
      return
    end

    @quotes = quotes if ActiveModel::Type::Boolean.new.cast(params[:returnQuotes])

    render('freightview/shipments/show', status: :created)
  end

  private

  def accessorial_errors
    unsupported = @payload.unsupported_accessorials.map do |property|
      { message: t('freightview.ltl_shipments.create.unsupported_accessorial'), property: }
    end
    unserviceable = (@payload.accessorial_codes.uniq - offered_accessorial_codes).map do |code|
      { message: t('freightview.ltl_shipments.create.unserviceable_accessorial', code:), property: :accessorials }
    end

    unsupported + unserviceable
  end

  def accessorials
    @accessorials ||= Accessorial.with_transponder_codes(@payload.accessorial_codes, broker_customer: @shipment.broker_customer)
  end

  def declared_freight_classes? = @shipment.declared_freight_classes.compact.any? && !@shipment.calculated_freight_classes?
  def offered_accessorial_codes = accessorials.map { |accessorial| accessorial.transponder_code.to_sym }

  def quotes
    Shipment::QuotableRatesService.call(@shipment, declared_freight_classes: declared_freight_classes?, user_type: :customer)
  end

  def shipment_accessorials_attributes = accessorials.map { |accessorial| { accessorial: } }
  def shipment_params = params.expect(shipment: Freightview::LTLShipmentPayload::PERMITTED)
end
