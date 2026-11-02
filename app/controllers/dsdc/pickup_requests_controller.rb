class DSDC::PickupRequestsController < DSDC::ApplicationController
  LOOKUP_TYPES = ['PickupConfirmationID', 'PRO'].freeze

  before_action :require_lookup_type, only: %i[show]
  before_action :set_shipments
  before_action :set_pickup_requests
  before_action :set_pickup_request
  before_action :set_pickup_payload, only: %i[create update]

  helper_method :testing?

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid_record
  rescue_from ArgumentError, with: :render_bad_request

  wrap_parameters :pickup_request, format: :json, include: DSDC::PickupPayload::ROOT_KEYS

  def create
    authorize!(@pickup_request, to: :manage?)

    unless testing? ? @pickup_payload.valid? : @pickup_payload.save
      render_error(@pickup_payload.errors.full_messages.to_sentence, status: :bad_request)
      return
    end

    render(:create)
  end

  def destroy
    authorize!(@pickup_request, to: :manage?)

    unless @pickup_request.cancel
      render_error(@pickup_request.errors.full_messages.to_sentence, status: :bad_request)
      return
    end

    render(:create)
  end

  def show
    authorize!(@pickup_request, to: :view?)

    stale?(@pickup_request, @pickup_request.shipments)
  end

  def update
    authorize!(@pickup_request, to: :manage?)

    unless testing? ? @pickup_payload.valid? : @pickup_payload.save
      render_error(@pickup_payload.errors.full_messages.to_sentence, status: :bad_request)
      return
    end

    render(:create)
  end

  private

  def pickup_request_params = params.expect(pickup_request: DSDC::PickupPayload::PERMITTED)
  def render_invalid_record(error) = render_error(error.record.errors.full_messages.to_sentence, status: :bad_request)

  def require_lookup_type
    return if LOOKUP_TYPES.include?(params[:lookupType])

    render_error(t('dsdc.pickup_requests.show.lookup_type', lookup_types: LOOKUP_TYPES.to_sentence), status: :bad_request)
  end

  def set_pickup_payload
    @pickup_payload = DSDC::PickupPayload.new(pickup_request_params, pickup_request: @pickup_request, user: current_user)
  end

  def set_pickup_request
    @pickup_request = if params.key?(:pickup_id)
                        @pickup_requests.active.find(params.expect(:pickup_id))
                      elsif params[:lookupType] == 'PickupConfirmationID'
                        @pickup_requests.includes(shipments: :receiver_address).find(params.expect(:lookupValue))
                      elsif params[:lookupType] == 'PRO'
                        @pickup_requests.find(@shipments.find_by!(load_id: params.expect(:lookupValue)).pickup_request_id)
                      else
                        PickupRequest.new(created_by: current_user)
                      end
  end

  def set_pickup_requests = @pickup_requests = authorized_scope(PickupRequest.all)
  def set_shipments = @shipments = authorized_scope(Shipment.all)
  def testing? = @pickup_payload&.test?
end
