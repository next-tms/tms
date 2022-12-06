# frozen_string_literal: true

# == Schema Information
#
# Table name: shipments
#
# @!attribute id
#   @return [Integer]
# @!attribute bol
#   @return [String]
# @!attribute bol_notes
#   @return [String]
# @!attribute booked_at
#   @return [Time]
# @!attribute broker_bol_shipment_fingerprint
#   @return [String]
# @!attribute broker_dispatch_sheet_shipment_fingerprint
#   @return [String]
# @!attribute broker_notes
#   @return [String]
# @!attribute broker_quote_shipment_fingerprint
#   @return [String]
# @!attribute canceled_at
#   @return [Time]
# @!attribute carrier_charge_cents
#   @return [Integer]
# @!attribute carrier_charge_currency
#   @return [String]
# @!attribute carrier_cost_cents
#   @return [Integer]
# @!attribute carrier_cost_currency
#   @return [String]
# @!attribute customer_notes
#   @return [String]
# @!attribute customer_reference
#   @return [String]
# @!attribute delivered_at
#   @return [Time]
# @!attribute delivery_appointment_at
#   @return [Time]
# @!attribute delivery_appointment_on
#   @return [Date]
# @!attribute delivery_eta_on
#   @return [Date]
# @!attribute delivery_hours_end_at
#   @return [String]
# @!attribute delivery_hours_start_at
#   @return [String]
# @!attribute departed_origin_terminal_at
#   @return [Time]
# @!attribute dispatched_at
#   @return [Time]
# @!attribute lift_gate_delivery
#   @return [Boolean]
# @!attribute lift_gate_pickup
#   @return [Boolean]
# @!attribute load
#   @return [Integer]
# @!attribute lost_on
#   @return [Date]
# @!attribute notify
#   @return [Boolean]
# @!attribute out_for_delivery_at
#   @return [Time]
# @!attribute pending_appointment_since
#   @return [Date]
# @!attribute picked_up
#   @return [Boolean]
# @!attribute picked_up_at
#   @return [Time]
# @!attribute pickup_confirmation
#   @return [String]
# @!attribute pickup_driver_assigned_at
#   @return [Time]
# @!attribute pickup_eta_at
#   @return [String]
# @!attribute pickup_hours_end_at
#   @return [String]
# @!attribute pickup_hours_start_at
#   @return [String]
# @!attribute pickup_on
#   @return [Date]
# @!attribute priority
#   @return [Integer]
# @!attribute pro
#   @return [String]
# @!attribute promised_delivery_by
#   @return [Time]
# @!attribute public_notes
#   @return [String]
# @!attribute quote_only
#   @return [Boolean]
# @!attribute quoted_delivery_by
#   @return [Time]
# @!attribute receiver_available_at
#   @return [Time]
# @!attribute receiver_contact_email
#   @return [String]
# @!attribute receiver_contact_name
#   @return [String]
# @!attribute receiver_contact_phone
#   @return [String]
# @!attribute receiver_name
#   @return [String]
# @!attribute receiver_unavailable_at
#   @return [Time]
# @!attribute shipper_available_at
#   @return [Time]
# @!attribute shipper_bol
#   @return [String]
# @!attribute shipper_contact_email
#   @return [String]
# @!attribute shipper_contact_name
#   @return [String]
# @!attribute shipper_contact_phone
#   @return [String]
# @!attribute shipper_name
#   @return [String]
# @!attribute shipper_reference
#   @return [String]
# @!attribute shipper_unavailable_at
#   @return [Time]
# @!attribute status
#   @return [String]
# @!attribute total_charges_cents
#   @return [Integer]
# @!attribute total_charges_currency
#   @return [String]
# @!attribute total_cost_cents
#   @return [Integer]
# @!attribute total_cost_currency
#   @return [String]
# @!attribute tracking_carrier_pickup_confirmation
#   @return [String]
# @!attribute tracking_carrier_pro
#   @return [String]
# @!attribute truckload
#   @return [Boolean]
# @!attribute value_cents
#   @return [Integer]
# @!attribute value_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute applied_rate_id
#   @return []
# @!attribute broker_carrier_id
#   @return [Integer]
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return [Integer]
# @!attribute created_by_id
#   @return []
# @!attribute dispatcher_id
#   @return []
# @!attribute load_id
#   @return [Integer]
# @!attribute quote_id
#   @return [String]
# @!attribute receiver_address_id
#   @return []
# @!attribute shipper_address_id
#   @return []
# @!attribute tracking_carrier_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_shipments_on_applied_rate_id        (applied_rate_id)
#  index_shipments_on_broker_customer_id     (broker_customer_id)
#  index_shipments_on_broker_id_and_load_id  (broker_id,load_id) UNIQUE
#  index_shipments_on_broker_notes           (broker_notes)
#  index_shipments_on_created_by_id          (created_by_id)
#  index_shipments_on_dispatcher_id          (dispatcher_id)
#  index_shipments_on_receiver_address_id    (receiver_address_id)
#  index_shipments_on_shipper_address_id     (shipper_address_id)
#  index_shipments_on_tracking_carrier_id    (tracking_carrier_id)
#  index_shipments_on_updated_by_id          (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (applied_rate_id => rates.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (dispatcher_id => users.id)
#  fk_rails_...  (receiver_address_id => addresses.id)
#  fk_rails_...  (shipper_address_id => addresses.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class Shipment < ApplicationRecord
  include Shipment::Documentable
  include Shipment::Fingerprintable
  include Shipment::HasPaymentTransactions
  include Shipment::HasReceivables
  include Shipment::Interstellarable

  include Problematic

  attr_accessor :dispatch_pickup
  attr_reader :previous_changes

  before_save :sanitize_addresses_street
  before_save :set_previous_changes

  audited

  ransacker :load_id do
    Arel.sql("to_char(\"#{table_name}\".\"load_id\", '99999999')")
  end

  scope :canceled, -> { where.not(canceled_at: nil) }
  scope :canceled_recently, -> { where('canceled_at > ?', 1.day.ago) }
  scope :active, -> { where.not(id: canceled) }

  scope :booked, -> { active.where.not(booked_at: nil).where(dispatched_at: nil) }
  scope :pending_dispatch, lambda {
                             active.where.not(broker_carrier: nil).where(dispatched_at: nil).where(picked_up_at: nil).where(out_for_delivery_at: nil).where(delivered_at: nil)
                           }
  scope :pending_found, -> { active.pending_delivery.where.not(lost_on: nil) }
  scope :pending_pickup, -> { active.where.not(dispatched_at: nil).where(picked_up_at: nil) }

  scope :pending_quotation, lambda {
    where(broker_carrier: nil, canceled_at: nil)
      .or(
        where(broker_carrier: nil)
        .where(id: canceled_recently)
      )
  }

  scope :pending_delivery, lambda {
    active
      .where.not(picked_up_at: nil)
      .where(delivered_at: nil)
  }

  scope :pending_departure, lambda {
    active
      .where.not(picked_up_at: nil)
      .where(departed_origin_terminal_at: nil)
      .where(delivered_at: nil)
  }

  scope :missing_delivery_appointment, lambda {
    joins(:broker_accessorials)
      .where(
        'broker_accessorials.id IN (?)',
        BrokerAccessorial.where(
          accessorial_id:
          [
            Accessorial.find_by_interstellar_code('appointment_delivery').id,
            Accessorial.find_by_interstellar_code('residential_delivery').id
          ]
        ).pluck(:id)
      )
      .or(
        Shipment
        .where.not(pending_appointment_since: nil)
      )
      .pending_delivery
      .where(delivery_appointment_on: nil)
      .where(delivery_appointment_at: nil)
  }

  scope :missing_pro, -> { active.pending_delivery.where(pro: ['', nil]) }

  scope :missing_cost, -> { active.where.not(id: pending_quotation).where(carrier_cost_cents: 0) }

  scope :missing_charge, -> { active.where.not(id: pending_quotation).where(carrier_charge_cents: 0) }

  scope :missing_delivery_eta_on, -> { where(delivery_eta_on: ['', nil]) }

  scope :not_missing_delivery_eta_on, -> { where.not(id: missing_delivery_eta_on) }

  scope :missing_pricing, lambda {
    active.missing_cost.or(active.missing_charge).where.not(picked_up_at: nil)
  }

  scope :delivered, -> { where.not(delivered_at: nil) }

  scope :late_per_delivery_eta_on, lambda {
    where.not(id: delivered).where('delivery_eta_on < ?', Date.current)
  }

  scope :late_per_promised_delivery_by, lambda {
    where.not(id: delivered).where('promised_delivery_by < ?', Date.current)
  }

  scope :late_per_quoted_delivery_by, lambda {
    where.not(id: delivered).where('quoted_delivery_by < ?', Date.current + 3.days)
  }

  scope :late, lambda {
    where(id: late_per_promised_delivery_by).or(where(id: late_per_delivery_eta_on)).distinct
  }

  scope :not_late, -> { where.not(id: late) }

  belongs_to :broker
  belongs_to :broker_carrier, counter_cache: true, required: false

  belongs_to :dispatcher, class_name: 'User', required: false

  has_many :claims
  has_many :commissions, dependent: :destroy

  has_many :tracking_events, dependent: :destroy
  accepts_nested_attributes_for :tracking_events, allow_destroy: true, reject_if: :all_blank

  has_many :payment_transactions
  has_many :payments, through: :payment_transactions

  has_many :problems, as: :resolvable

  belongs_to :created_by, class_name: 'User', required: false
  belongs_to :updated_by, class_name: 'User', required: false

  has_many :shipment_items, dependent: :destroy
  has_many :items, through: :shipment_items
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  has_many :shipment_accessorials, dependent: :destroy
  accepts_nested_attributes_for :shipment_accessorials, allow_destroy: true, reject_if: :all_blank
  has_many :accessorials, through: :shipment_accessorials

  belongs_to :applied_rate, class_name: 'Rate', required: false
  has_many :rates, dependent: :destroy

  has_many :shipment_broker_accessorials, dependent: :destroy
  accepts_nested_attributes_for :shipment_broker_accessorials, allow_destroy: true, reject_if: :all_blank
  has_many :broker_accessorials, through: :shipment_broker_accessorials

  has_many :pickups

  belongs_to :receiver_address, class_name: 'Address', required: true
  belongs_to :shipper_address, class_name: 'Address', required: true

  belongs_to :tracking_carrier, class_name: 'Carrier', required: false

  belongs_to :broker_customer, required: false

  accepts_nested_attributes_for :receiver_address
  validates_associated :receiver_address, presence: true

  accepts_nested_attributes_for :shipper_address
  validates_associated :shipper_address, presence: true

  before_save :remove_tracking_events, if: -> { pro_changed? || tracking_carrier_pro_changed? }

  # Fix broker_accessorials when broker_customer changes
  before_save :recalculate_broker_accessorials, if: :broker_customer_id_changed?

  before_save :maybe_sync_broker_carrier_pickup_confirmation_and_pro
  before_save :maybe_sync_tracking_carrier_pickup_confirmation_and_tracking_carrier_pro

  # Remove tracking_carrier_* information when changed from broker to carrier
  before_save :maybe_remove_tracking_carrier, if: :broker_carrier_id_changed?
  before_save :maybe_remove_tracking_carrier_pickup_confirmation, if: :broker_carrier_id_changed?
  before_save :maybe_remove_tracking_carrier_pro, if: :broker_carrier_id_changed?

  # Prettify
  before_save :prettify_shipper_name, if: :shipper_name_changed?
  before_save :prettify_receiver_name, if: :receiver_name_changed?

  # Reference sanitization
  before_save :squish_bol, if: :will_save_change_to_bol?
  before_save :squish_pickup_confirmation, if: :will_save_change_to_pickup_confirmation?
  before_save :squish_pro, if: :will_save_change_to_pro?

  # Fill in missing DateTimes
  # before_save :maybe_update_dispatched_at_to_now, if: :pickup_confirmation_changed?
  before_save :maybe_update_out_for_delivery_at_to_delivered_at, if: :delivered_at_changed?
  before_save :set_delivery_appointment_on
  before_save :set_delivery_eta_on
  before_save :update_delivery_eta_on_to_out_for_delivery_at, if: :out_for_delivery_at_changed?

  before_save :maybe_book, if: :dispatched_at_changed?
  before_save :unbook, if: :canceled_at_changed?
  before_save :uncancel, if: :booked_at_changed?

  # Pricing
  before_save :set_total_charges
  before_save :set_total_cost
  before_save :build_commissions, if: lambda {
    broker_carrier_id_changed? || broker_customer_id_changed? || total_charges_cents_changed? || total_cost_cents_changed?
  }

  # Dispatcher
  before_save :assign_dispatcher

  monetize :carrier_charge_cents, allow_nil: true
  monetize :carrier_cost_cents, allow_nil: true
  monetize :total_cost_cents, allow_nil: true
  monetize :total_charges_cents, allow_nil: true
  monetize :value_cents, allow_nil: true

  phony_normalize :shipper_contact_phone, default_country_code: 'US'
  phony_normalize :receiver_contact_phone, default_country_code: 'US'

  after_create :notify_of_new_shipment
  before_save :send_notification

  # Remove applied_rate when carrier changes
  before_save :remove_applied_rate, if: :will_save_change_to_broker_carrier_id?
  before_save :remove_applied_rate, if: :will_save_change_to_tracking_carrier_id?

  before_save :validate_applied_rate_association, if: :will_save_change_to_applied_rate_id?

  validates :load_id, uniqueness: { scope: :broker }

  validate :validate_future_pickup_by, if: -> { dispatch_pickup }
  validate :validate_past_or_present_attributes
  validate :validate_pro_and_tracking_carrier_pro

  def applied_rate_uid=(rate_uid)
    rate = Rate.find_by_uid(rate_uid)
    return if rate.blank?

    self.carrier_cost = rate.cost
    self.applied_rate = rate
  end

  def booked_at=(val)
    return self.booked_at = DateTime.current if val == 'now' # for UI

    super
  end

  def canceled_at=(val)
    return self.canceled_at = DateTime.current if val == 'now' # for UI

    super
  end

  # Returns the actual carrier rather than any broker associated
  def carrier
    return nil if broker_carrier.blank?

    if broker_carrier.carrier.acts_as_broker?
      tracking_carrier
    else
      broker_carrier.carrier
    end
  end

  def dispatcher_full_name
    dispatcher&.full_name
  end

  def dispatch_incomplete?
    true_pickup_confirmation = tracking_carrier.blank? ? pickup_confirmation : tracking_carrier_pickup_confirmation
    if !broker_carrier.blank? && !dispatched_at.blank? && true_pickup_confirmation.blank? && (dispatched_at < DateTime.current - 15.minutes)
      return true
    end

    false
  end

  def missing_delivery_eta_on?
    delivery_eta_on.blank?
  end

  def total_broker_accessorial_charge
    return 0 if shipment_broker_accessorials.blank?

    shipment_broker_accessorials.map(&:charge).inject(0) { |sum, x| sum + (x.nil? ? Money.new(0) : x) }
  end

  def total_broker_accessorial_cost
    return 0 if shipment_broker_accessorials.blank?

    shipment_broker_accessorials.map(&:cost).inject(0) { |sum, x| sum + (x.nil? ? Money.new(0) : x) }
  end

  def profit
    total_charges - total_cost
  end

  def margin
    "#{((1 - (total_cost / total_charges)) * 100).round(1)}%"
  end

  def delivered?
    !delivered_at.blank?
  end

  def delivered_in_days
    return 'unknown' if picked_up_at.blank? || delivered_at.blank?
    return 'unknown' if delivered_at < picked_up_at

    picked_up_at.to_date.business_days_until delivered_at.to_date
  end

  def palletized_items
    return @palletized_items if @palletized_items

    unpalletized_packagings = Packaging.where(name: %w[carton pieces truckload])
    @palletized_items = items.where.not(packaging: unpalletized_packagings)
  end

  def palletized?
    @palletized ||= palletized_items.size == items.size
  end

  def loose_items
    @loose_items = items - palletized_items
  end

  def loose?
    @loose ||= !loose_items.empty?
  end

  def delivery_from
    tz = receiver_address&.time_zone
    return nil if tz.blank?

    from = promised_delivery_by.presence || delivery_appointment_at.presence || delivery_appointment_on.presence || delivery_eta_on.presence
    return from if from.present? && !from.is_a?(Date)

    if from.is_a?(Date)
      return from.in_time_zone(tz).beginning_of_day + 9.hours unless delivery_hours_start_at.present?

      formatted_offset = Time.current.in_time_zone(tz).formatted_offset
      return DateTime.parse("#{from} #{delivery_hours_start_at} #{formatted_offset}")
    end

    return 5.business_days.after(pickup_from.in_time_zone(tz)).beginning_of_day + 9.hours if pickup_from.present?

    nil
  end

  def delivery_by
    tz = receiver_address&.time_zone
    return nil if tz.blank?

    by = promised_delivery_by.presence || delivery_appointment_at.presence || delivery_appointment_on.presence || delivery_eta_on.presence
    return by if by.present? && !by.is_a?(Date)

    if by.is_a?(Date)
      return by.in_time_zone(tz).beginning_of_day + 17.hours unless delivery_hours_end_at.present?

      formatted_offset = Time.current.in_time_zone(tz).formatted_offset
      return DateTime.parse("#{by} #{delivery_hours_end_at} #{formatted_offset}")
    end

    return 5.business_days.after(pickup_by.in_time_zone(tz)).beginning_of_day + 17.hours if pickup_by.present?

    nil
  end

  def pickup_from
    return nil if pickup_on.blank?
    return nil if pickup_hours_start_at.blank?
    return nil if shipper_address&.time_zone.blank?

    formatted_offset = DateTime.now.in_time_zone(shipper_address.time_zone.name).formatted_offset

    DateTime.parse("#{pickup_on} #{pickup_hours_start_at} #{formatted_offset}").in_time_zone(shipper_address.time_zone)
  end

  def pickup_by
    return nil if pickup_on.blank?
    return nil if pickup_hours_end_at.blank?
    return nil if shipper_address&.time_zone.blank?

    formatted_offset = DateTime.now.in_time_zone(shipper_address.time_zone.name).formatted_offset

    DateTime.parse("#{pickup_on} #{pickup_hours_end_at} #{formatted_offset}")
  end

  def status
    return @status if @status

    @status = ''.dup
    @status = 'New'
    @status = 'Booked' if booked_at.present?
    @status = 'Quoted' if total_charges.present?
    @status = 'Booked, Quoted' if booked_at.present? && total_charges.present?
    @status = 'Dispatched' unless dispatched_at.blank?
    @status = 'Pickup Scheduled' if pickup_confirmation.present? && pickup_by.present?
    @status = 'In Transit' unless picked_up_at.blank?
    @status = 'Pending Delivery Appointment' unless pending_appointment_since.blank?
    @status = 'Delivery Scheduled' if !delivery_appointment_at.blank? || !delivery_appointment_on.blank?
    @status = 'Out for Delivery' unless out_for_delivery_at.blank?
    @status = 'Delivered' unless delivered_at.blank?
    @status = 'Canceled' unless canceled_at.blank?
    @status = "Late, #{@status}" if late?
    @status
  end

  def pending_departure?
    return false if picked_up_at.blank? || !delivered_at.blank?

    if picked_up_at < 52.hours.ago
      departed_origin_terminal_at.blank?
    else
      false
    end
  end

  def late?
    return @late if @late
    return @late = false unless delivered_at.blank?

    if !picked_up_at.blank?
      if !delivery_appointment_at.blank?
        return @late = true if DateTime.current > delivery_appointment_at
      elsif delivery_appointment_at.blank? && !delivery_appointment_on.blank?
        return @late = true if Date.current > delivery_appointment_on
      elsif !delivery_eta_on.blank? && (Date.current > delivery_eta_on)
        return @late = true
      end
      @late = true if !promised_delivery_by.blank? && (Date.current > promised_delivery_by)
    elsif !pickup_by.blank?
      @late = pickup_by < DateTime.current
    end
  end

  def accessorials
    return @accessorials if @accessorials

    broker_accessorials = self.broker_accessorials.where.not(accessorial_id: nil)
    @accessorials = broker_accessorials.blank? ? [] : Accessorial.where(id: broker_accessorials.map(&:accessorial_id))
  end

  # Set BrokerAccessorials based on codes (for API)
  def accessorial_codes=(codes)
    codes = codes.gsub(', ', ',').split(',') if codes.instance_of?(String)
    broker_accessorials = []
    codes.each do |code|
      broker_accessorial = broker_customer.broker_accessorials.where(code:)
      if broker_accessorial.blank?
        broker_accessorial = broker_customer.broker.broker_accessorials.where(code:)
        broker_accessorials << broker_accessorial.first unless broker_accessorial.blank?
      else
        broker_accessorials << broker_accessorial.first
      end
    end
    self.broker_accessorials = broker_accessorials.uniq
  end

  def accessorial_codes
    @accessorial_codes ||= accessorials.blank? ? [] : accessorials.map(&:code)
  end

  def accessorial_names
    @accessorial_names ||= accessorials.blank? ? [] : accessorials.map(&:name)
  end

  def assumed_accessorials
    return @assumed_accessorials if @assumed_accessorials

    @assumed_accessorials = BuildAssumedAccesorialsService.new(shipment: self).call
    # # TODO: Remove after Regression Testing
    # @assumed_accessorials = []
    #
    # # Airports
    # if !receiver_name.blank? && %w[airport hangar].any? do |word|
    #      receiver_name.downcase.include?(word)
    #    end
    #   @assumed_accessorials << Accessorial.find_by_code('DAIR')
    # end
    # if !shipper_name.blank? && %w[airport hangar].any? do |word|
    #      shipper_name.downcase.include?(word)
    #    end
    #   @assumed_accessorials << Accessorial.find_by_code('PAIR')
    # end
    # if !receiver_address.types.blank? && (receiver_address.types.include? 'airport')
    #   @assumed_accessorials << Accessorial.find_by_code('DAIR')
    # end
    # if !shipper_address.types.blank? && (shipper_address.types.include? 'airport')
    #   @assumed_accessorials << Accessorial.find_by_code('PAIR')
    # end
    #
    # # Military bases
    # if !receiver_address.types.blank? && (receiver_address.types.include? 'military')
    #   @assumed_accessorials << Accessorial.find_by_code('DMIL')
    # end
    # if !shipper_address.types.blank? && (shipper_address.types.include? 'military')
    #   @assumed_accessorials << Accessorial.find_by_code('PMIL')
    # end
    #
    # # Residential
    # if receiver_address.residential? || accessorial_codes.include?('DRES')
    #   @assumed_accessorials << Accessorial.find_by_code('DRES')
    #   @assumed_accessorials << Accessorial.find_by_code('DAPP')
    #   if items.order(Arel.sql('items.weight / items.quantity DESC')).limit(1).first.weight >= 200
    #     @assumed_accessorials << Accessorial.find_by_code('DLIF')
    #   end
    # end
    # if shipper_address.residential? || accessorial_codes.include?('PRES')
    #   @assumed_accessorials << Accessorial.find_by_code('PRES')
    #   @assumed_accessorials << Accessorial.find_by_code('PAPP')
    #   if items.order(Arel.sql('items.weight / items.quantity DESC')).limit(1).first.weight >= 200
    #     @assumed_accessorials << Accessorial.find_by_code('PLIF')
    #   end
    # end
    #
    # # Restaurant
    # @assumed_accessorials << Accessorial.find_by_code('PRST') if shipper_address.restaurant?
    # @assumed_accessorials << Accessorial.find_by_code('DRST') if receiver_address.restaurant?
    #
    # # Appointment delivery
    # if !bol_notes.blank? && (bol_notes.downcase.include? 'must contact')
    #   @assumed_accessorials << Accessorial.find_by_code('DAPP')
    # end
    #
    # @assumed_accessorials = @assumed_accessorials.uniq
  end

  def assumed_accessorial_codes
    @assumed_accessorial_codes ||= assumed_accessorials.blank? ? [] : assumed_accessorials.map(&:code)
  end

  def assumed_accessorial_names
    @assumed_accessorial_names ||= assumed_accessorials.blank? ? [] : assumed_accessorials.map(&:name)
  end

  def suggested_accessorials
    return [] if assumed_accessorials.blank?

    @suggested_accessorials = assumed_accessorials - (accessorials.blank? ? [] : accessorials)
  end

  def suggested_accessorial_codes
    @suggested_accessorial_codes ||= suggested_accessorials.blank? ? [] : suggested_accessorials.map(&:code)
  end

  def suggested_broker_accessorials
    return [] if suggested_accessorials.blank?

    @suggested_broker_accessorials = []
    suggested_accessorials.each do |suggested_accessorial|
      broker_accessorial = broker_customer.broker_accessorials.where(code: suggested_accessorial.code)
      if broker_accessorial.blank?
        broker_accessorial = broker_customer.broker.broker_accessorials.where(code: suggested_accessorial.code)
        @suggested_broker_accessorials << broker_accessorial.first unless broker_accessorial.blank?
      else
        @suggested_broker_accessorials << broker_accessorial.first
      end
    end
    @suggested_broker_accessorials
  end

  def freight_classes(use_forced_freight_class:)
    items.inject([]) { |arr, item| arr << item.api_freight_class(use_forced_freight_class:) }
  end

  def calculated_freight_classes
    @calculated_freight_classes ||= freight_classes(use_forced_freight_class: false)
  end

  def forced_freight_classes
    @forced_freight_classes ||= freight_classes(use_forced_freight_class: true)
  end

  def incomplete?
    !shipper_address.full_address? || !receiver_address.full_address? || shipper_name.blank? || receiver_name.blank? ? true : false
  end

  def total_weight
    unless @total_weight
      @total_weight = 0
      items.each do |item|
        @total_weight += item.weight
      end
    end
    @total_weight
  end

  def total_pieces
    unless @total_pieces
      @total_pieces = 0
      items.each do |item|
        @total_pieces += item.quantity
      end
    end
    @total_pieces
  end

  def total_cubic_ft(rounded:)
    total_cubic_ft = 0
    items.each do |item|
      return nil if item.cubic_ft(rounded: false).blank?

      total_cubic_ft += item.cubic_ft(rounded: false)
    end
    rounded ? ('%0.2f' % total_cubic_ft).to_f : total_cubic_ft
  end

  def total_density(rounded:)
    total_density = 0
    items.each do |item|
      return nil if item.density(rounded: false).blank?

      total_density += item.density(rounded: false)
    end
    rounded ? ('%0.2f' % total_density).to_f : total_density
  end

  def longest_dimension
    return @longest_dimension if @longest_dimension
    return nil if items.map(&:w).include?(nil) || items.map(&:l).include?(nil)

    longest_l = items.max_by(&:l).l
    longest_w = items.max_by(&:w).w
    @longest_dimension = longest_l > longest_w ? longest_l : longest_w
  end

  # Return Item for each physical item with `quantity = 1`
  def flattened_items
    return @flattened_items if @flattened_items

    @flattened_items = []
    items.each do |item|
      item.quantity.times do
        new_item = item.dup
        new_item.quantity = 1
        new_item.weight = item.weight.to_f / item.quantity if item.quantity > 1
        @flattened_items << new_item
      end
    end
    @flattened_items
  end

  def linear_ft
    return @linear_ft if @linear_ft

    items = self.items
    @linear_ft = 0
    true_items = []
    item_rows = []

    items.each do |item|
      return @linear_ft = nil unless item.l && item.w && item.h

      item.quantity.times do
        # Rotate the item if longer that 102 inches
        true_items << if item.long_side > 102
                        { l: item.short_side, w: item.long_side, allocated: false }
                      else
                        { l: item.long_side, w: item.short_side, allocated: false }
                      end
      end
    end

    true_items = true_items.sort_by { |k| k[:l] } # Find longest piece first

    i = 0
    row_l = 0
    row_w = 0
    row_tries = 0

    loop do
      items_allocated_count = 0
      true_items.each do |true_item|
        items_allocated_count += 1 if true_item[:allocated]
      end
      if true_items[i].nil?
        i = 0
        redo
      end
      if items_allocated_count == true_items.count
        item_rows << { l: row_l, w: row_w }
        break
      end
      if true_items[i][:allocated]
        i += 1
        redo
      end
      if row_tries > (true_items.count * true_items.count)
        item_rows << { l: row_l, w: row_w }
        row_l = 0
        row_w = 0
        row_tries = 0
        redo
      end
      if true_items[i][:l] <= (102 - row_l)
        row_l += true_items[i][:l]
        row_w = true_items[i][:w] if true_items[i][:w] > row_w
        true_items[i][:allocated] = true
        i += 1
      elsif true_items[i][:l] > (102 - row_l)
        i += 1
        row_tries += 1
        redo
      end
    end

    item_rows.each do |item_row|
      @linear_ft += item_row[:w]
    end

    @linear_ft = (@linear_ft / 12.to_f).ceil
    # @linear_ft = ( @linear_ft / 12.to_f )
  end

  def accessible_by?(user)
    return false unless user.is_a?(User)

    if user.broker?
      return true if user.has_role?('dispatch') || user.has_role?('sales_rep') || user.has_role?('accounting')
    elsif user.customer?
      return broker_customer == user.broker_customer
    end

    false
  end

  # Dispatcher
  # @note Public method because `Broker::ShipmentsController#new` calls it
  def assign_dispatcher
    return if broker.blank? || dispatcher.present?

    preferred_dispatchers = broker_customer&.dispatchers.presence || broker.users.active.dispatchers

    self.dispatcher = preferred_dispatchers.order(Arel.sql('RANDOM()')).take
  end

  def to_param
    load_id.to_s
  end

  def requires_charges_confirmed_on_receivables?
    broker_customer&.requires_charges_confirmed_on_receivables || broker.requires_charges_confirmed_on_receivables
  end

  private

  def build_commissions
    return if broker_customer.blank? || total_cost == Money.new(0) || total_charges == Money.new(0)

    unless commissions.blank?
      if commissions.pluck(:paid).include?(true)
        errors.add(:base, 'Pricing cannot be updated because commission(s) have already been paid')
      else
        commissions.destroy_all
      end
    end

    # total_charges, total_cost not yet serialized with pre-save attributes so we call Money.new
    profit = Money.new(total_charges_cents - total_cost_cents)

    broker_customer.broker_customer_sales_reps.find_each do |broker_customer_sales_rep|
      amount = profit * (broker_customer_sales_rep.commission_percent.to_f / 100).round(2)
      next if amount.zero?

      commissions.build(
        user_id: broker_customer_sales_rep.user_id,
        amount:
      )
    end
  end

  def sanitize_addresses_street
    [[:receiver_name, receiver_address], [:shipper_name, shipper_address]].each do |set|
      attribute = set[0]
      address = set[1]

      next if address.street.blank? || !address.street.strip.upcase.start_with?('C/O')

      new_value = send(attribute) || ''
      new_value = "#{new_value} #{address.street}".strip
      send("#{attribute}=", new_value)

      address.street = address.street2
      address.street2 = nil
    end
  end

  def set_previous_changes
    @previous_changes = changes
  end

  def validate_future_pickup_by
    return unless pickup_by

    errors.add(:pickup_on, 'date and time must be in the future') if pickup_by < DateTime.current
  end

  def validate_past_or_present_attributes
    now = Time.current

    %i[delivered_at out_for_delivery_at picked_up_at pickup_driver_assigned_at].each do |attribute|
      val = public_send(attribute)
      next unless val.present? && val > now

      errors.add(attribute, 'cannot be in the future')
    end
  end

  def validate_pro_and_tracking_carrier_pro
    return unless pro_changed? || tracking_carrier_pro_changed? || broker_carrier.blank? || pro.blank?

    error = NotImplementedError

    # TODO: Call this on the Interstellar::Carrier class directly (see ITR-18)
    begin
      interstellar_carrier = broker_carrier.to_interstellar_carrier

      if interstellar_carrier.present? && !interstellar_carrier.valid_tracking_number?(pro)
        errors.add(:base, "Pro #{pro} is invalid for #{broker_carrier.carrier.name}")
      end
    rescue error
    end

    return if tracking_carrier.blank?

    # TODO: Call this on the Interstellar::Carrier class directly (see ITR-18)
    # if tracking_carrier.interstellar_class.present? && tracking_carrier_pro.present?
    #   begin
    #     interstellar_class = tracking_carrier.interstellar_class
    #
    #     if interstellar_class.present? && !interstellar_class.valid_tracking_number?(tracking_carrier_pro)
    #       errors.add(:base, "Carrier #{tracking_carrier.name} pro #{tracking_carrier_pro} is invalid")
    #     end
    #   rescue error
    #   end
    # end

    if tracking_carrier_pickup_confirmation.present? && pickup_confirmation.present? &&
       tracking_carrier_pickup_confirmation == pickup_confirmation
      errors.add(
        :tracking_carrier_pickup_confirmation,
        "cannot match pickup ref #{pickup_confirmation} from #{broker_carrier.carrier.name}"
      )
    end

    return unless tracking_carrier_pro.present? && pro.present? && tracking_carrier_pro == pro

    errors.add(:tracking_carrier_pro, "cannot match pro #{pro} from #{broker_carrier.carrier.name}")
  end

  def remove_tracking_events
    tracking_events.destroy_all
  end

  def validate_applied_rate_association
    return if applied_rate.blank?

    if applied_rate.shipment_fingerprint != fingerprint
      errors.add(:rate, 'Rate fingerprint and shipment fingerprint do not match')
      return
    end

    self.carrier_cost = applied_rate.cost
    self.carrier_charge = broker_customer.carrier_charge_calculator(
      carrier_cost: applied_rate.cost,
      shipment: self
    ) || 0

    self.broker_carrier = applied_rate.broker_carrier
    self.tracking_carrier = applied_rate.tracking_carrier

    self.quote_id = applied_rate.reference
    self.quoted_delivery_by = applied_rate.transit_days.to_i.business_days.after(pickup_on || DateTime.current)

    return if updated_by&.broker_customer.blank?

    total_charges = broker_customer.carrier_charge_calculator(
      carrier_cost: applied_rate.cost,
      shipment: self
    )

    total_charges += broker_accessorials.where.not(upcharge_cents: 0).sum(:upcharge_cents) unless total_charges.blank?

    self.total_charges = total_charges || 0
  end

  # Remove applied_rate when carrier changes
  def remove_applied_rate
    self.applied_rate = nil
  end

  # Fix broker_accessorials when broker_customer changes
  def recalculate_broker_accessorials
    new_broker_accessorials = []
    broker_accessorials.each do |broker_accessorials|
      new_broker_accessorials << broker_customer.eligible_broker_accessorials.find_by_code(broker_accessorials.code)
    end
    self.broker_accessorials = new_broker_accessorials
  end

  def maybe_sync_broker_carrier_pickup_confirmation_and_pro
    return if broker_carrier.blank?
    return unless broker_carrier.pickup_number_is_tracking_number?

    self.pickup_confirmation = pro if pickup_confirmation.blank? && !pro.blank?
    self.pro = pickup_confirmation if pro.blank? && !pickup_confirmation.blank?
  end

  def maybe_sync_tracking_carrier_pickup_confirmation_and_tracking_carrier_pro
    return if tracking_carrier.blank?
    return unless tracking_carrier.pickup_number_is_tracking_number?

    if tracking_carrier_pickup_confirmation.blank? && !tracking_carrier_pro.blank?
      self.tracking_carrier_pickup_confirmation = tracking_carrier_pro
    end

    return unless tracking_carrier_pro.blank? && !tracking_carrier_pickup_confirmation.blank?

    self.tracking_carrier_pro = tracking_carrier_pickup_confirmation
  end

  # Remove tracking_carrier_* information when changed from broker to carrier
  def maybe_remove_tracking_carrier
    return if broker_carrier.blank?

    self.tracking_carrier = nil unless broker_carrier.carrier.acts_as_broker
  end

  def maybe_remove_tracking_carrier_pickup_confirmation
    return if broker_carrier.blank?

    self.tracking_carrier_pickup_confirmation = nil unless broker_carrier.carrier.acts_as_broker
  end

  def maybe_remove_tracking_carrier_pro
    return if broker_carrier.blank?

    self.tracking_carrier_pro = nil unless broker_carrier.carrier.acts_as_broker
  end

  # Fill in missing DateTimes
  def maybe_update_out_for_delivery_at_to_delivered_at
    self.out_for_delivery_at = delivered_at if out_for_delivery_at.blank?
  end

  def maybe_update_dispatched_at_to_now
    self.dispatched_at = DateTime.current if dispatched_at.blank?
  end

  def set_delivery_appointment_on
    return unless delivery_appointment_on.blank? && !delivery_appointment_at.blank?

    self.delivery_appointment_on = delivery_appointment_at.in_time_zone(shipper_address.time_zone).to_date
  end

  def set_delivery_eta_on
    return unless delivery_eta_on.blank? && !delivery_appointment_on.blank?

    self.delivery_eta_on = delivery_appointment_on
  end

  def maybe_book
    self.booked_at = dispatched_at if booked_at.blank?
  end

  def unbook
    self.booked_at = nil
  end

  def uncancel
    self.canceled_at = nil
  end

  def update_delivery_eta_on_to_out_for_delivery_at
    self.delivery_eta_on = out_for_delivery_at.to_date if delivery_eta_on.blank? && !out_for_delivery_at.blank?
  end

  # Prettify
  def prettify_shipper_name
    return if shipper_name == broker_customer&.customer&.name
    return unless (shipper_name == shipper_name.downcase) || (shipper_name == shipper_name.upcase)

    self.shipper_name = shipper_name.titleize
  end

  def prettify_receiver_name
    return if receiver_name == broker_customer&.customer&.name
    return unless (receiver_name == receiver_name.downcase) || (receiver_name == receiver_name.upcase)

    self.receiver_name = receiver_name.titleize
  end

  # Reference sanitization
  def squish_bol
    self.bol = bol&.squish
  end

  def squish_pickup_confirmation
    self.pickup_confirmation = pickup_confirmation&.squish
  end

  def squish_pro
    self.pro = pro&.squish
  end

  # Pricing
  def set_total_charges
    return if carrier_charge.blank?

    self.total_charges = carrier_charge + total_broker_accessorial_charge
  end

  def set_total_cost
    return if carrier_charge.blank?

    self.total_cost = carrier_cost + total_broker_accessorial_cost
  end

  # Notifications
  def notify_of_new_shipment
    return if Rails.env.test?

    notification = ShipmentNotification.with(shipment: self, attribute_changed: :new_shipment)
    notification.deliver_later(users_to_notify)
  end

  def users_to_notify
    user_ids = (broker_customer&.sales_reps&.ids || []) +
               (broker.users.broker.with_role('dispatch')&.ids || []) +
               (broker.users.broker.with_role('root')&.ids || [])

    user_ids -= broker.users.broker.with_role('notifications:-dispatch')&.ids || []

    unless updated_by.blank?
      if updated_by.receive_notifications_from_self?
        user_ids << updated_by.id
      else
        user_ids -= [updated_by.id]
      end
    end

    User.distinct.active.where(id: user_ids)
  end

  def send_notification
    changed_attributes.each_key do |key|
      return false if !UserMailer.respond_to?(key) || changes[key][1].blank?

      notification = ShipmentNotification.with(shipment: self, attribute_changed: key)
      return notification.deliver_later(dispatcher) if key == 'dispatcher_id'

      notification.deliver_later(users_to_notify)
    end
  end
end
