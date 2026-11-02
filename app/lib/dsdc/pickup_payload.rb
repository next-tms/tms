class DSDC::PickupPayload
  include ActiveModel::Validations

  SHIPMENT_DETAILS = [
    :additionalShipperInfo,
    :crossRefPro,
    :deliveryBeginDate,
    :deliveryDateType,
    :deliveryEndDate,
    :description,
    :freightClass,
    :grossShipmentWeight,
    :handlingUnitCount,
    :handlingUnitType,
    :hazmatCheck,
    :hazmatContactName,
    :hazmatContactPhoneNumber,
    :hazmatContractNumber,
    :individualPieceType,
    :individualPieces,
    :netShipmentWeight,
    :nmfc,
    :nmfcSub,
    :proNumber,
    :shipperRef,
    :specialInstructionsDelivery,
    :specialInstructionsPickup,
    :weight,
    {
      descriptionDetails: [],
      handlingUnitDetails: [%i[height length totalLinearFeetofShipment totalUnitCount totalWeight unitCount unitType weight width]],
      referenceNumbers: [%i[refPieceCount referenceNumber referenceType]],
      shipmentServices: [%i[serviceCode serviceDescription]]
    }
  ].freeze
  PERMITTED = [
    :carrierPickupNumber,
    :closeTime,
    :confirmationEmail,
    :cubicFeet,
    :customer,
    :dockContactEmail,
    :dockContactName,
    :dockContactPhone,
    :dockDoorNumber,
    :grossPickupWeight,
    :handlingUnitCount,
    :isTest,
    :linearFeet,
    :loadedBy,
    :openDate,
    :openTime,
    :pickupLocationTimeZone,
    :readyDate,
    :readyTime,
    :requestFunction,
    :sealNumber,
    :trailerNumber,
    :warehouseName,
    :weightUofM,
    {
      billToAddress: [
        %i[
          btAccountNumber
          btAddressLine1
          btAddressLine2
          btAddressName
          btCity
          btContactName
          btCountry
          btPhoneNumber
          btState
          btStoreNumber
          btZip
        ]
      ],
      destinationAddress: [
        %i[
          cneeAddressLine1
          cneeAddressLine2
          cneeAddressName
          cneeCity
          cneeContactName
          cneeCountry
          cneePhoneNumber
          cneeState
          cneeStoreNumber
          cneeZip
        ]
      ],
      emergencyContact: [%i[emergEmail emergName emergPhone]],
      pickupAddress: [
        %i[
          orgAccountNumber
          orgAddressLine1
          orgAddressLine2
          orgAddressName
          orgCity
          orgContactName
          orgCountry
          orgPhoneNumber
          orgState
          orgStoreNumber
          orgZip
        ]
      ],
      shipmentDetails: [SHIPMENT_DETAILS]
    }
  ].freeze
  ROOT_KEYS = PERMITTED.flat_map { |entry| entry.is_a?(Hash) ? entry.keys : entry }.map(&:to_s).freeze

  attr_reader :params, :pickup_request, :user

  validate :validate_pickup_hours
  validate :validate_shipments

  def initialize(params, pickup_request:, user:)
    @params = params
    @pickup_request = pickup_request
    @user = user
  end

  def closes_after_ready? = closes_at > ready_at
  def closes_at = Time.iso8601(params.expect(:closeTime))

  def pickup_request_attributes = { accepted_pickup_on: ready_at.to_date, reschedule_reason: nil }

  def pro_numbers = Array(params[:shipmentDetails]).filter_map { |shipment_details| shipment_details[:proNumber].presence }.uniq
  def ready_at = Time.iso8601(params[:readyTime].presence || params.expect(:readyDate))

  def save
    PickupRequest.transaction do
      next false unless valid?

      pickup_request.update!(**pickup_request_attributes, shipments:)
      shipments.each { |shipment| shipment.update!(**shipment_attributes, updated_by: user) }
    end
  end

  def shipment_attributes
    {
      pickup_hours_end_at: closes_at.strftime('%-l:%M %p'),
      pickup_hours_start_at: ready_at.strftime('%-l:%M %p'),
      pickup_on: ready_at.to_date
    }
  end

  def shipments = @shipments ||= user.shipments.active.includes(:pickup_request).where(load_id: pro_numbers).lock.to_a
  def test? = DSDC.boolean(params.expect(:isTest))

  private

  def scheduled_elsewhere?(other_pickup_request)
    other_pickup_request.present? && other_pickup_request != pickup_request && !other_pickup_request.canceled?
  end

  def validate_pickup_hours = closes_after_ready? || errors.add(:base, I18n.t('dsdc.pickup_requests.closes_before_ready'))

  def validate_shipments
    missing_pro_numbers = pro_numbers - shipments.map { |shipment| shipment.load_id.to_s }
    scheduled_shipments = shipments.select { |shipment| scheduled_elsewhere?(shipment.pickup_request) }

    errors.add(:base, I18n.t('dsdc.pickup_requests.pro_numbers_missing')) if pro_numbers.empty?
    errors.add(:base, I18n.t('dsdc.pickup_requests.shipments_picked_up')) if shipments.any?(&:picked_up?)

    if missing_pro_numbers.any?
      errors.add(:base, I18n.t('dsdc.pickup_requests.shipments_missing', pro_numbers: missing_pro_numbers.to_sentence))
    end

    return if scheduled_shipments.none?

    errors.add(:base, I18n.t('dsdc.pickup_requests.shipments_scheduled', pro_numbers: scheduled_shipments.map(&:load_id).to_sentence))
  end
end
