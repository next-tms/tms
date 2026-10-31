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
# @!attribute broker_and_broker_customer_notes
#   @return [String]
# @!attribute broker_notes
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
# @!attribute charges_confirmed
#   @return [Boolean]
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
# @!attribute fingerprint
#   @return [String]
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
#  index_shipments_on_applied_rate_id      (applied_rate_id)
#  index_shipments_on_broker_customer_id   (broker_customer_id)
#  index_shipments_on_broker_notes         (broker_notes)
#  index_shipments_on_created_by_id        (created_by_id)
#  index_shipments_on_dispatcher_id        (dispatcher_id)
#  index_shipments_on_load_id              (load_id) UNIQUE
#  index_shipments_on_receiver_address_id  (receiver_address_id)
#  index_shipments_on_shipper_address_id   (shipper_address_id)
#  index_shipments_on_status               (status)
#  index_shipments_on_tracking_carrier_id  (tracking_carrier_id)
#  index_shipments_on_updated_by_id        (updated_by_id)
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
  class << self
    def last_load_id = maximum(:load_id) || Setting.first_load_id.to_i

    def ransackable_attributes(_auth_object = nil)
      [
        'bol_notes',
        'broker_notes',
        'created_at',
        'delivered_at',
        'load_id',
        'picked_up_at',
        'pro',
        'receiver_contact_name',
        'receiver_name',
        'shipper_contact_name',
        'shipper_name',
        'tracking_carrier_pro'
      ]
    end

    def ransackable_associations(_auth_object = nil)
      ['broker_carrier', 'broker_customer', 'receiver_address', 'shipper_address']
    end
  end

  include Discussable
  include Documentable
  include Problematic

  include Shipment::Fingerprintable
  include Shipment::HasPaymentTransactions
  include Shipment::HasReceivables
  include Shipment::Transponible

  DOCUMENTABLE_TYPES = %i[broker_bol broker_label broker_dispatch_sheet broker_quote].freeze
  REFERENCE_ATTRIBUTES = %i[bol customer_reference pickup_confirmation pro quote_id shipper_reference].freeze

  attr_accessor :dispatch_pickup

  audited

  belongs_to :broker_carrier, counter_cache: true, optional: true

  belongs_to :dispatcher, class_name: 'User'

  has_associated_audits

  has_many :claims, dependent: :restrict_with_error
  has_many :commissions, dependent: :destroy

  has_many :tracking_events, dependent: :destroy
  accepts_nested_attributes_for :tracking_events, allow_destroy: true, reject_if: :all_blank

  has_many :payment_transactions, dependent: :restrict_with_error
  has_many :payments, through: :payment_transactions

  has_many :pickups, dependent: :destroy

  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :items, dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  has_many :shipment_accessorials, dependent: :destroy
  accepts_nested_attributes_for :shipment_accessorials, allow_destroy: true, reject_if: :all_blank
  has_many :accessorials, through: :shipment_accessorials

  belongs_to :applied_rate, class_name: 'Rate', optional: true
  has_many :rates, dependent: :destroy

  has_many :shipment_broker_accessorials, dependent: :destroy
  accepts_nested_attributes_for :shipment_broker_accessorials, allow_destroy: true, reject_if: :all_blank
  has_many :broker_accessorials, through: :shipment_broker_accessorials

  has_one_attached :broker_bol
  has_one_attached :broker_dispatch_sheet
  has_one_attached :broker_label
  has_one_attached :broker_quote
  has_one_attached :carrier_bol   # TODO: Rename to carrier_scanned_bol
  has_one_attached :carrier_label # TODO: Rename to carrier_bol
  has_one_attached :carrier_pod
  has_one_attached :broker_carrier_quote

  belongs_to :receiver_address, class_name: 'Address'
  belongs_to :shipper_address, class_name: 'Address'

  belongs_to :tracking_carrier, class_name: 'Carrier', optional: true

  belongs_to :broker_customer, optional: true

  after_create :notify_of_new_shipment

  before_save :sanitize_addresses_street
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
  before_save :build_commissions
  before_save :send_notification
  # Remove applied_rate when carrier changes
  before_save :remove_applied_rate, if: :will_save_change_to_broker_carrier_id?
  before_save :remove_applied_rate, if: :will_save_change_to_tracking_carrier_id?
  before_save :validate_applied_rate_association, if: :will_save_change_to_applied_rate_id?

  before_validation :set_dispatcher
  before_validation :set_status

  enum :status,
       {
         booked_quoted: 'booked_quoted',
         booked: 'booked',
         canceled: 'canceled',
         delivered: 'delivered',
         delivery_scheduled: 'delivery_scheduled',
         dispatched: 'dispatched',
         in_transit: 'in_transit',
         new_shipment: 'new_shipment',
         out_for_delivery: 'out_for_delivery',
         pending_delivery_appointment: 'pending_delivery_appointment',
         pickup_scheduled: 'pickup_scheduled',
         quoted: 'quoted'
       }

  monetize :carrier_charge_cents, allow_nil: true
  monetize :carrier_cost_cents, allow_nil: true
  monetize :total_cost_cents, allow_nil: true
  monetize :total_charges_cents, allow_nil: true
  monetize :value_cents, allow_nil: true

  normalizes :receiver_contact_email, :shipper_contact_email, with: ->(value) { value.downcase }
  normalizes(
    *REFERENCE_ATTRIBUTES,
    :receiver_name,
    :receiver_contact_email,
    :receiver_contact_name,
    :shipper_name,
    :shipper_contact_email,
    :shipper_contact_name,
    with: ->(value) { value.squish }
  )

  phony_normalize :shipper_contact_phone, default_country_code: 'US'
  phony_normalize :receiver_contact_phone, default_country_code: 'US'

  ransacker :load_id do
    Arel.sql("to_char(\"#{table_name}\".\"load_id\", '99999999')")
  end

  scope :active,                        -> { not_canceled } # TODO: Remove, use :not_canceled
  scope :booked,                        -> { active.where.not(booked_at: nil).where(dispatched_at: nil) }
  scope :canceled_recently,             -> { where('canceled_at > ?', 1.day.ago) }
  scope :late,                          -> { where(id: late_per_promised_delivery_by).or(where(id: late_per_delivery_eta_on)).distinct }
  scope :late_per_delivery_eta_on,      -> { not_delivered.where(delivery_eta_on: ...Date.current) }
  scope :late_per_promised_delivery_by, -> { not_delivered.where(promised_delivery_by: ...Date.current) }
  scope :late_per_quoted_delivery_by,   -> { not_delivered.where(quoted_delivery_by: ...(Date.current + 3.days)) }
  scope :missing_charge,                -> { active.where.not(id: pending_quotation).where(carrier_charge_cents: 0) }
  scope :missing_cost,                  -> { active.where.not(id: pending_quotation).where(carrier_cost_cents: 0) }
  scope :missing_delivery_appointment, -> {
                                         accessorial_ids = BrokerAccessorial
                                                           .where(
                                                             accessorial_id: Accessorial
                                                                             .where(
                                                                               freight_kit_code: [
                                                                                 'appointment_delivery',
                                                                                 'residential_delivery'
                                                                               ]
                                                                             )
                                                                             .select(:id)
                                                           )
                                                           .ids

                                         joins(:broker_accessorials)
                                           .where(broker_accessorials: { accessorial_id: accessorial_ids })
                                           .or(where.not(pending_appointment_since: nil))
                                           .pending_delivery
                                           .where(delivery_appointment_on: nil, delivery_appointment_at: nil)
                                       }
  scope :missing_delivery_eta_on,       -> { where(delivery_eta_on: ['', nil]) }
  scope :missing_pricing,               -> { active.missing_cost.or(active.missing_charge).where.not(picked_up_at: nil) }
  scope :missing_pro,                   -> { active.pending_delivery.where(pro: ['', nil]) }
  scope :not_late,                      -> { where.not(id: late) }
  scope :not_missing_delivery_eta_on,   -> { where.not(id: missing_delivery_eta_on) }
  scope :pending_delivery,              -> { active.where.not(picked_up_at: nil).not_delivered }
  scope :pending_departure,             -> { active.where.not(picked_up_at: nil).where(departed_origin_terminal_at: nil).not_delivered }
  scope :pending_dispatch,              -> {
    active.where.not(broker_carrier: nil).where(dispatched_at: nil, picked_up_at: nil, out_for_delivery_at: nil).not_delivered
  }
  scope :pending_found,                 -> { active.pending_delivery.where.not(lost_on: nil) }
  scope :pending_pickup,                -> { active.where.not(dispatched_at: nil).where(picked_up_at: nil) }
  scope :pending_quotation,             -> {
    where(broker_carrier: nil, canceled_at: nil).or(where(broker_carrier: nil).where(id: canceled_recently))
  }

  validates :load_id, presence: true, uniqueness: true

  validate :validate_future_pickup_by, if: -> { dispatch_pickup }
  validate :validate_reference_attributes
  validate :validate_past_or_present_attributes
  validate :validate_pro_and_tracking_carrier_pro

  accepts_nested_attributes_for :receiver_address
  accepts_nested_attributes_for :shipper_address

  def applied_rate_uid=(rate_uid)
    rate = Rate.find_by(uid: rate_uid)
    return if rate.blank?

    self.carrier_cost = rate.cost
    self.applied_rate = rate
  end

  def booked_at=(val)
    super(val == 'now' ? Time.current : val)
  end

  def broker_carrier_bol_requires_tracking_number?
    broker_carrier.present? && broker_carrier.bol_requires_tracking_number?
  end

  def calculated_freight_classes?
    return !applied_rate.declared_freight_classes? if applied_rate.present?

    return broker_customer.always_show_quotes_based_on_calculated_classes? if broker_customer.present?

    false
  end

  def canceled_at=(val)
    super(val == 'now' ? Time.current : val)
  end

  # Returns the actual carrier rather than any broker associated
  def carrier
    return if broker_carrier.blank?

    broker_carrier.carrier.acts_as_broker? ? tracking_carrier : broker_carrier.carrier
  end

  def dispatcher_full_name
    dispatcher&.full_name
  end

  def dispatch_incomplete?
    true_pickup_confirmation = tracking_carrier.blank? ? pickup_confirmation : tracking_carrier_pickup_confirmation
    return true if broker_carrier.present? && dispatched_at.present? && true_pickup_confirmation.blank? && (dispatched_at < 15.minutes.ago)

    false
  end

  # @return [BrokerCarrier::ActiveRecord_Relation]
  def eligible_broker_carriers(user_type = :customer)
    broker_customer&.eligible_broker_carriers(user_type) || BrokerCarrier.where(broker_customer: nil)
  end

  def eligible_discussable_contacts
    ids = if broker_customer.present?
            broker_customer.contacts.customer.ids +
              broker_customer.dispatchers.pluck(:contact_id) +
              broker_customer.sales_reps.pluck(:contact_id)
          else
            User.with_role('dispatch').broker.pluck(:contact_id)
          end
    ids << updated_by.contact_id if updated_by.present?

    # Fallback
    ids = User.broker.with_role('root').pluck(:contact_id) if ids.empty?

    Contact.where(id: ids)
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
    delivered_at.present?
  end

  def delivered_in_days
    return 'unknown' if picked_up_at.blank? || delivered_at.blank?
    return 'unknown' if delivered_at < picked_up_at

    picked_up_at.to_date.business_days_until(delivered_at.to_date)
  end

  def palletized_items
    return @palletized_items if @palletized_items

    unpalletized_packagings = Packaging.where(name: ['carton', 'pieces', 'truckload'])
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
    Shipment::DeliveryDateService.new(shipment: self).delivery_from
  end

  def delivery_by
    Shipment::DeliveryDateService.new(shipment: self).delivery_by
  end

  def picked_up?
    picked_up_at.present?
  end

  def pickup_from
    return if pickup_on.blank? || pickup_hours_start_at.blank? || shipper_address&.time_zone.blank?

    formatted_offset = Time.zone.now.in_time_zone(shipper_address.time_zone.name).formatted_offset
    Time.zone.parse("#{pickup_on} #{pickup_hours_start_at} #{formatted_offset}").in_time_zone(shipper_address.time_zone)
  end

  def pickup_by
    return if pickup_on.blank? || pickup_hours_end_at.blank? || shipper_address&.time_zone.blank?

    formatted_offset = Time.zone.now.in_time_zone(shipper_address.time_zone.name).formatted_offset
    Time.zone.parse("#{pickup_on} #{pickup_hours_end_at} #{formatted_offset}")
  end

  def pending_departure?
    return false if picked_up_at.blank? || delivered_at.present?

    picked_up_at < 52.hours.ago ? departed_origin_terminal_at.blank? : false
  end

  def late?
    return false if delivered_at.present?
    return pickup_by.present? && pickup_by < Time.current if picked_up_at.blank?

    @late ||= late_per_delivery_schedule? || (promised_delivery_by.present? && Date.current > promised_delivery_by)
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
        broker_accessorial = BrokerAccessorial.where(code:)
        broker_accessorials << broker_accessorial.first if broker_accessorial.present?
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
  end

  def assumed_accessorial_codes
    @assumed_accessorial_codes ||= assumed_accessorials.blank? ? [] : assumed_accessorials.map(&:code)
  end

  def assumed_accessorial_names
    @assumed_accessorial_names ||= assumed_accessorials.blank? ? [] : assumed_accessorials.map(&:name)
  end

  def suggested_accessorials
    return [] if assumed_accessorials.blank?

    @suggested_accessorials = assumed_accessorials - (accessorials.presence || [])
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
        broker_accessorial = BrokerAccessorial.where(code: suggested_accessorial.code)
        @suggested_broker_accessorials << broker_accessorial.first if broker_accessorial.present?
      else
        @suggested_broker_accessorials << broker_accessorial.first
      end
    end
    @suggested_broker_accessorials
  end

  def freight_classes(use_declared_freight_class:)
    items.inject([]) { |arr, item| arr << item.api_freight_class(use_declared_freight_class:) }
  end

  def calculated_freight_classes
    @calculated_freight_classes ||= freight_classes(use_declared_freight_class: false)
  end

  def declared_freight_classes
    @declared_freight_classes ||= freight_classes(use_declared_freight_class: true)
  end

  def incomplete?
    [shipper_address, receiver_address].map(&:full_address?).any?(false) || [shipper_name, receiver_name].any?(&:blank?)
  end

  def whodunnit(column)
    raise ArgumentError, "Column \"#{column}\" doesn't exist" if self.class.column_names.exclude?(column)

    audits.includes(:user).select { |audit| audit.audited_changes.keys.include?('total_cost_cents') }.last&.user || nil
  end

  def total_weight
    items.sum(:weight)
  end

  def total_pieces
    items.sum(:quantity)
  end

  def total_cubic_ft(rounded:)
    return if items.any? { |item| item.cubic_ft(rounded: false).blank? }

    value = items.sum { |item| item.cubic_ft(rounded: false) * item.quantity }
    return value unless rounded

    value.ceil
  end

  def total_density(rounded:)
    return if items.any? { |item| item.density(rounded: false).blank? }

    total_density = items.sum { |item| item.density(rounded: false) }
    rounded ? format('%0.2f', total_density).to_f : total_density
  end

  def longest_dimension
    return @longest_dimension if @longest_dimension
    return if items.map(&:w).include?(nil) || items.map(&:l).include?(nil)

    longest_l = items.max_by(&:l).l
    longest_w = items.max_by(&:w).w
    @longest_dimension = [longest_l, longest_w].max
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

  def accessible_by?(user)
    if user.broker?
      return true if broker_customer.blank?

      return user.any_role?(
        :accounts_payable,
        :accounts_receivable,
        :dispatch
      ) || broker_customer.sales_reps.include?(user)
    end

    user.customer? && broker_customer == user.companyable
  end

  def to_param
    load_id.to_s
  end

  # @return [BrokerCarrier::ActiveRecord_Relation]
  def valid_broker_carriers_for_quotation(user_type = :customer)
    broker_carrier_ids = []
    broker_carrier_ids += if broker_customer.blank?
                            BrokerCarrier.blanket.api_configured.ids
                          else
                            broker_customer.eligible_broker_carriers(user_type).api_configured.ids
                          end

    broker_carrier_ids += if broker_customer.blank?
                            PricingRule.where(broker_carrier: BrokerCarrier.blanket.api_unconfigured.select(:id)).pluck(:broker_carrier_id)
                          else
                            PricingRule.where(broker_carrier: broker_customer.eligible_broker_carriers(user_type)).pluck(:broker_carrier_id)
                          end

    BrokerCarrier.where(id: broker_carrier_ids)
  end

  def requires_charges_confirmed_on_receivables?
    broker_customer&.requires_charges_confirmed_on_receivables || Setting.requires_charges_confirmed_on_receivables
  end

  def undocumentable_reasons
    {}.tap do |builder|
      DOCUMENTABLE_TYPES.each do |documentable_type|
        service = "DocumentableService::Shipment::#{documentable_type.to_s.camelcase}".constantize.new(self)

        missing_requirements = service.missing_requirements
        next if missing_requirements.empty?

        builder[documentable_type] = [].tap do |reasons_builder|
          missing_requirements.map do |requirement|
            reasons_builder << "#{self.class.human_attribute_name(requirement).downcase.upcase_first} is invalid"
          end
        end
      end
    end
  end

  def users_to_notify
    user_ids = (broker_customer&.sales_reps&.ids || []) +
               (User.broker.with_role('dispatch')&.ids || []) +
               (User.broker.with_role('root')&.ids || [])

    user_ids -= User.broker.with_role('notifications:-dispatch')&.ids || []

    if updated_by.present?
      if updated_by.receive_notifications_from_self?
        user_ids << updated_by.id
      else
        user_ids -= [updated_by.id]
      end
    end

    User.distinct.active.where(id: user_ids)
  end

  private

  def build_commissions
    return unless broker_customer.present? && [total_charges_cents, total_cost_cents].all?(&:positive?)

    return if %i[broker_customer_id total_charges_cents total_cost_cents]
              .map { |attribute| public_send("will_save_change_to_#{attribute}?") }
              .none?(true)

    if commissions.present?
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

      commissions.build(user_id: broker_customer_sales_rep.user_id, amount:)
    end
  end

  def late_per_delivery_schedule?
    return Time.current > delivery_appointment_at if delivery_appointment_at.present?
    return Date.current > delivery_appointment_on if delivery_appointment_on.present?

    delivery_eta_on.present? && Date.current > delivery_eta_on
  end

  def sanitize_addresses_street
    [[:receiver_name, receiver_address], [:shipper_name, shipper_address]].each do |set|
      attribute = set[0]
      address = set[1]

      next unless address&.street.present? && address.street.strip.upcase.start_with?('C/O')

      new_value = public_send(attribute) || ''
      new_value = "#{new_value} #{address.street}".strip
      public_send("#{attribute}=", new_value)

      address.street = address.street2
      address.street2 = nil
    end
  end

  def set_dispatcher
    return if dispatcher&.broker?

    preferred_dispatchers = broker_customer&.dispatchers.presence || User.active.dispatchers

    self.dispatcher = preferred_dispatchers.order(Arel.sql('RANDOM()')).take
  end

  def set_status
    self.status = if canceled_at.present?
                    :canceled
                  elsif delivered_at.present?
                    :delivered
                  elsif out_for_delivery_at.present?
                    :out_for_delivery
                  elsif delivery_appointment_at.present? || delivery_appointment_on.present?
                    :delivery_scheduled
                  elsif pending_appointment_since.present?
                    :pending_delivery_appointment
                  elsif picked_up_at.present?
                    :in_transit
                  elsif pickup_confirmation.present? && pickup_by.present?
                    :pickup_scheduled
                  elsif dispatched_at.present?
                    :dispatched
                  elsif booked_at.present? && total_charges.present?
                    :booked_quoted
                  elsif total_charges.present?
                    :quoted
                  elsif booked_at.present?
                    :booked
                  else
                    :new_shipment
                  end
  end

  def validate_future_pickup_by
    return unless pickup_by

    errors.add(:pickup_on, 'date and time must be in the future') if pickup_by < Time.current
  end

  def validate_reference_attributes
    REFERENCE_ATTRIBUTES.each do |attribute|
      next unless public_send("#{attribute}_changed?")

      value = public_send(attribute)
      next if value.blank?

      case value.scan(/[a-zA-Z]+/).join.downcase
      when 'none' then errors.add(attribute, 'cannot be “none”')
      when 'verbal' then errors.add(attribute, 'cannot be “verbal”')
      end

      ['bol', 'pro', 'Ref:', 'P/O', 'PO', 'P/U', 'S/O', 'SO', '#'].each do |prefix|
        matched_prefix = value.match(/\A#{Regexp.escape(prefix)}/i)
        next if matched_prefix.blank?

        errors.add(attribute, "cannot start with “#{matched_prefix}”")
      end
    end
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
    return unless (pro_changed? || tracking_carrier_pro_changed?) && broker_carrier.present? && pro.present?

    # TODO: Call this on the FreightKit::Carrier class directly (see ITR-18)
    begin
      freight_kit_carrier = broker_carrier.to_freight_kit_carrier

      if freight_kit_carrier.present? && !freight_kit_carrier.valid_tracking_number?(pro)
        errors.add(:base, "Pro #{pro} is invalid for #{broker_carrier.carrier.name}")
      end
    rescue ArgumentError, NotImplementedError
      nil
    end

    return if tracking_carrier.blank?

    # TODO: Call this on the FreightKit::Carrier class directly (see ITR-18)
    # if tracking_carrier.freight_kit_class.present? && tracking_carrier_pro.present?
    #   begin
    #     freight_kit_class = tracking_carrier.freight_kit_class
    #
    #     if freight_kit_class.present? && !freight_kit_class.valid_tracking_number?(tracking_carrier_pro)
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
    self.carrier_charge = broker_customer.carrier_charge_calculator(carrier_cost: applied_rate.cost, shipment: self) || 0

    self.broker_carrier = applied_rate.broker_carrier
    self.tracking_carrier = applied_rate.tracking_carrier

    self.quote_id = applied_rate.reference
    self.quoted_delivery_by = applied_rate.transit_days.to_i.business_days.after(pickup_on || Time.current)

    return unless updated_by.present? && updated_by.companyable.is_a?(BrokerCustomer)

    total_charges = broker_customer.carrier_charge_calculator(carrier_cost: applied_rate.cost, shipment: self)

    total_charges += broker_accessorials.where.not(upcharge_cents: 0).sum(:upcharge_cents) if total_charges.present?

    self.total_charges = total_charges || 0
  end

  # Remove applied_rate when carrier changes
  def remove_applied_rate
    self.applied_rate = nil
  end

  # Fix broker_accessorials when broker_customer changes
  def recalculate_broker_accessorials
    new_broker_accessorials = broker_accessorials.map do |broker_accessorials|
      broker_customer.eligible_broker_accessorials.find_by(code: broker_accessorials.code)
    end
    self.broker_accessorials = new_broker_accessorials
  end

  def maybe_sync_broker_carrier_pickup_confirmation_and_pro
    return if broker_carrier.blank?
    return unless broker_carrier.pickup_number_is_tracking_number?

    self.pickup_confirmation = pro if pickup_confirmation.blank? && pro.present?
    self.pro = pickup_confirmation if pro.blank? && pickup_confirmation.present?
  end

  def maybe_sync_tracking_carrier_pickup_confirmation_and_tracking_carrier_pro
    return if tracking_carrier.blank?
    return unless tracking_carrier.pickup_number_is_tracking_number?

    if tracking_carrier_pickup_confirmation.blank? && tracking_carrier_pro.present?
      self.tracking_carrier_pickup_confirmation = tracking_carrier_pro
    end

    return unless tracking_carrier_pro.blank? && tracking_carrier_pickup_confirmation.present?

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
    self.dispatched_at = Time.current if dispatched_at.blank?
  end

  def set_delivery_appointment_on
    return unless delivery_appointment_on.blank? && delivery_appointment_at.present?

    self.delivery_appointment_on = delivery_appointment_at.in_time_zone(shipper_address.time_zone).to_date
  end

  def set_delivery_eta_on
    return unless delivery_eta_on.blank? && delivery_appointment_on.present?

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
    self.delivery_eta_on = out_for_delivery_at.to_date if delivery_eta_on.blank? && out_for_delivery_at.present?
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

    ShipmentNotifier.with(attribute_changed: :new_shipment, shipment: self).deliver(users_to_notify)
  end

  def send_notification
    changed_attributes.each_key do |key|
      return false if !UserMailer.respond_to?(key) || changes[key][1].blank?

      notification = ShipmentNotifier.with(shipment: self, attribute_changed: key)
      return notification.deliver(dispatcher) if key == 'dispatcher_id'

      notification.deliver(users_to_notify)
    end
  end
end
