class DSDC::BOLsController < DSDC::ApplicationController
  before_action :set_shipment, only: %i[destroy update]
  before_action :set_importer, only: %i[create update]

  rescue_from ActionController::ParameterMissing, ArgumentError, with: :render_formatting_error

  helper_method :testing?

  wrap_parameters :bill_of_lading, format: :json, include: EBOL::Importer::ROOT_KEYS

  def create
    @shipment = Shipment.new(booked_at: Time.current, broker_customer:, quote_only: false)
    authorize!(@shipment, to: :create?)

    if @shipment.broker_customer.blank?
      render_failure('300', t('.unknown_customer', account: @importer.bill_to_account))
      return
    end

    @shipment.assign_attributes(@importer.shipment_attributes(@shipment))
    @shipment.created_by = current_user
    @shipment.updated_by = current_user

    unless testing? ? @shipment.valid? : @shipment.save
      render_validation_errors
      return
    end

    @images = images unless testing?

    render(:show)
  end

  def destroy
    authorize!(@shipment, to: :manage?)

    if @shipment.picked_up_at.present?
      render_failure('500', t('.picked_up'))
      return
    end

    Shipment.transaction do
      @shipment.update!(booked_at: nil, updated_by: current_user)
      @shipment.update!(canceled_at: Time.current)
    end

    @information = []

    render(:show)
  end

  def update
    authorize!(@shipment, to: :manage?)

    if @shipment.picked_up_at.present?
      render_failure('500', t('.picked_up'))
      return
    end

    @shipment.assign_attributes(@importer.shipment_attributes(@shipment))
    @shipment.updated_by = current_user

    unless testing? ? @shipment.valid? : @shipment.save
      render_validation_errors
      return
    end

    @images = images unless testing?

    render(:show)
  end

  private

  def bol_params = params.expect(bill_of_lading: EBOL::Importer::PERMITTED)

  def broker_customer
    return current_user.companyable if current_user&.customer?

    current_user&.broker_customers&.find_by(id: @importer.bill_to_account)
  end

  def encoded_document(document_type, code)
    Base64.strict_encode64("DocumentableService::Shipment::Create#{document_type.to_s.camelcase}Job".constantize.render(@shipment))
  rescue StandardError => e
    raise unless Rails.env.production?

    Sentry.capture_exception(e)
    @information << { code:, message: t("dsdc.bols.#{document_type}_failed"), type: 'Warning' }
    nil
  end

  def images
    {
      bol: (encoded_document(:broker_bol, '1200') if @importer.include_bol?),
      shipping_labels: (encoded_document(:broker_label, '1300') if @importer.include_shipping_labels?)
    }.compact
  end

  def render_failure(code, message) = render('dsdc/bols/errors', locals: { errors: [{ code:, message: }] }, status: :bad_request)
  def render_formatting_error(error) = render_failure('400', error.message)

  def render_validation_errors
    errors = @shipment.errors.full_messages.map { |message| { code: '300', message: } }

    render('dsdc/bols/errors', locals: { errors: }, status: :bad_request)
  end

  def set_importer
    @importer = EBOL::Importer.new(bol_params)
    @information = @importer.information
  end

  def set_shipment = @shipment = authorized_scope(Shipment.active).find_by!(load_id: params[:pro])

  def testing? = @importer&.test?
end
