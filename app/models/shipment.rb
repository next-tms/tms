# frozen_string_literal: true

class Shipment < ApplicationRecord
  scope :canceled, -> { where.not(canceled_at: nil) }
  scope :canceled_recently, -> { canceled.where('canceled_at > ?', 1.day.ago) }
  scope :active, -> { where.not(id: canceled) }

  scope :booked, -> { active.where.not(booked_at: nil).where(dispatched_at: nil) }
  scope :pending_dispatch, lambda {
                             active.where.not(broker_carrier: nil).where(dispatched_at: nil).where(picked_up_at: nil).where(out_for_delivery_at: nil).where(delivered_at: nil)
                           }
  scope :pending_found, -> { active.pending_delivery.where.not(lost_on: nil) }
  scope :pending_pickup, -> { active.where.not(dispatched_at: nil).where(picked_up_at: nil) }
  scope :pending_quotation, -> { where(broker_carrier: nil) } # Include canceled
  scope :pending_delivery, lambda {
                             active.where.not(picked_up_at: nil).where.not(departed_origin_terminal_at: nil).where(delivered_at: nil)
                           }
  scope :pending_departure, lambda {
                              active.where.not(picked_up_at: nil).where(departed_origin_terminal_at: nil).where(delivered_at: nil)
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
  scope :missing_deliver_by, -> { where(deliver_by: ['', nil]) }
  scope :not_missing_deliver_by, -> { where.not(id: missing_deliver_by) }
  scope :missing_pricing, -> { active.missing_cost.or(active.missing_charge) }

  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :late_per_deliver_by, -> { where.not(id: delivered).where('deliver_by < ?', Date.current) }
  scope :late_per_promised_delivery_by, -> { where.not(id: delivered).where('promised_delivery_by < ?', Date.current) }
  scope :late_per_quoted_delivery_by, lambda {
                                        where.not(id: delivered).where('quoted_delivery_by < ?', Date.current + 3.days)
                                      }
  scope :late, -> { where(id: late_per_promised_delivery_by).or(where(id: late_per_deliver_by)).distinct }
  scope :not_late, -> { where.not(id: late) }

  belongs_to :broker
  belongs_to :broker_carrier, counter_cache: true, required: false

  has_many :commissions, autosave: true, dependent: :destroy
  has_many :broker_customer_sales_reps, through: :commissions

  has_many :tracking_events
  accepts_nested_attributes_for :tracking_events, allow_destroy: true, reject_if: :all_blank

  has_many :payment_transactions
  has_many :payments, through: :payment_transactions

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

  has_one :pickup

  has_one_attached :broker_bol
  has_one_attached :broker_dispatch_sheet
  has_one_attached :broker_quote
  has_one_attached :carrier_bol
  has_one_attached :carrier_pod

  belongs_to :receiver_address, class_name: 'Address', required: true
  belongs_to :shipper_address, class_name: 'Address', required: true

  belongs_to :tracking_carrier, class_name: 'Carrier', required: false

  belongs_to :broker_customer, required: false

  accepts_nested_attributes_for :receiver_address
  validates_associated :receiver_address, presence: true

  accepts_nested_attributes_for :shipper_address
  validates_associated :shipper_address, presence: true

  before_save :maybe_create_payment_transaction, if: :picked_up_at_changed?
  before_save :remove_tracking_events, if: :pro_or_tracking_carrier_pro_changed?

  # Fix broker_accessorials when broker_customer changes
  before_save :recalculate_broker_accessorials, if: :broker_customer_id_changed?

  # Remove tracking_carrier_* information when changed from broker to carrier
  before_save :maybe_remove_tracking_carrier, if: :broker_carrier_id_changed?
  before_save :maybe_remove_tracking_carrier_pickup_confirmation, if: :broker_carrier_id_changed?
  before_save :maybe_remove_tracking_carrier_pro, if: :broker_carrier_id_changed?

  # Prettify
  before_save :prettify_shipper_name, if: :shipper_name_changed?
  before_save :prettify_receiver_name, if: :receiver_name_changed?

  # DateTime sanitization
  before_save :sanitize_pending_appointment_since, if: :pending_appointment_since_changed?
  before_save :sanitize_dispatched_at, if: :dispatched_at_changed?
  before_save :sanitize_pickup_driver_assigned_at, if: :pickup_driver_assigned_at_changed?
  before_save :sanitize_pickup_on, if: :pickup_on_changed?
  before_save :sanitize_picked_up_at, if: :picked_up_at_changed?
  before_save :sanitize_out_for_delivery_at, if: :out_for_delivery_at_changed?
  before_save :sanitize_delivery_appointment_at, if: :delivery_appointment_at_changed?
  before_save :sanitize_delivery_appointment_on, if: :delivery_appointment_on_changed?
  before_save :sanitize_delivered_at, if: :delivered_at_changed?
  before_save :sanitize_deliver_by, if: :deliver_by_changed?
  before_save :sanitize_departed_origin_terminal_at, if: :departed_origin_terminal_at_changed?
  before_save :sanitize_quoted_delivery_by, if: :quoted_delivery_by_changed?

  # Reference sanitization
  before_save :squish_bol, if: :will_save_change_to_bol?
  before_save :squish_pickup_confirmation, if: :will_save_change_to_pickup_confirmation?
  before_save :squish_pro, if: :will_save_change_to_pro?

  # Fill in missing DateTimes
  # before_save :maybe_update_dispatched_at_to_now, if: :pickup_confirmation_changed?
  before_save :maybe_update_out_for_delivery_at_to_delivered_at, if: :delivered_at_changed?
  before_save :update_deliver_by_to_out_for_delivery_at, if: :out_for_delivery_at_changed?

  before_save :maybe_book, if: :dispatched_at_changed?
  before_save :unbook, if: :canceled_at_changed?
  before_save :uncancel, if: :booked_at_changed?

  # Pricing
  before_save :set_total_charges
  before_save :set_total_cost
  before_save :build_commissions

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

  def applied_rate_uid=(rate_uid)
    rate = Rate.find_by_uid(rate_uid)
    return if rate.blank?

    self.carrier_cost = rate.cost
    self.applied_rate = rate
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

  def carrier_cost_encoded=(str)
    self.carrier_cost = Money.new(Base64.decode64(str).to_f * 100)
  end

  def carrier_charge_encoded=(str)
    self.carrier_charge = Money.new(Base64.decode64(str).to_f * 100)
  end

  def dispatch_incomplete?
    true_pickup_confirmation = tracking_carrier.blank? ? pickup_confirmation : tracking_carrier_pickup_confirmation
    if !broker_carrier.blank? && !dispatched_at.blank? && true_pickup_confirmation.blank? && (dispatched_at < DateTime.current - 15.minutes)
      return true
    end

    false
  end

  def fetch_carrier_bol
    return nil if pro.blank?

    path = InterstellarApiClient.fetch_bol(broker_carrier: broker_carrier, tracking_number: pro)
    return nil if path.blank?

    unless path.is_a?(String)
      Rollbar.debug("Shipment#fetch_carrier_bol id=#{id}, path is a #{path.class}")
      return nil
    end

    carrier_bol.attach(io: File.open(path), filename: "#{load_id} BOL (Carrier).pdf", content_type: 'application/pdf')
  end

  def fetch_carrier_pod
    return nil if pro.blank?

    path = InterstellarApiClient.fetch_pod(broker_carrier: broker_carrier, tracking_number: pro)
    return nil if path.blank?

    carrier_pod.attach(io: File.open(path), filename: "#{load_id} POD.pdf", content_type: 'application/pdf')
  end

  def fingerprint
    str = ''.dup
    str += flattened_items.to_json
    str += accessorial_codes.to_json
    str += shipper_address.pretty(', ') unless shipper_address.blank?
    str += receiver_address.pretty(', ') unless receiver_address.blank?

    Digest::SHA2.hexdigest(str)
  end

  def broker_documents_fingerprint
    str = ''.dup
    str += accessorial_codes&.to_json || ''
    str += bol || ''
    str += bol_notes || ''
    str += broker_carrier_id&.to_s || ''
    str += deliver_by.to_s || ''
    str += delivery_appointment_at.to_s || ''
    str += delivery_appointment_on.to_s || ''
    str += delivery_hours_end_at.to_s || ''
    str += delivery_hours_start_at.to_s || ''
    str += flattened_items&.to_json || ''
    str += pickup_hours_end_at || ''
    str += pickup_hours_start_at || ''
    str += pro || ''
    str += quote_id || ''
    str += receiver_address.pretty(', ') unless receiver_address.blank?
    str += shipper_address.pretty(', ') unless shipper_address.blank?
    str += shipper_bol || ''
    str += shipper_reference || ''
    str += total_charges_cents&.to_s || ''
    str += total_cost_cents&.to_s || ''
    str += tracking_carrier_id&.to_s || ''

    Digest::SHA2.hexdigest(str)
  end

  def missing_deliver_by?
    deliver_by.blank?
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

  def pickup_by
    return nil if pickup_on.blank?

    shipper_address&.time_zone&.local_to_utc(pickup_on.end_of_day)
  end

  # Interstellar
  def interstellar_tracking
    return @interstellar_tracking if @interstellar_tracking

    # Do not check broker_carrier.account, broker_carrier.username, broker_carrier.password as `nil` can be passed on
    return nil if pro.blank? && pickup_confirmation.blank?
    return nil if broker_carrier.blank? || broker_carrier.carrier.scac.blank?

    tracking_number = if pro.blank?
                        broker_carrier.carrier.has_traceable_pickup_confirmation? ? pickup_confirmation : nil
                      else
                        pro
                      end
    return nil if tracking_number.blank?

    @interstellar_tracking = InterstellarApiClient.fetch_tracking(
      broker_carrier: broker_carrier,
      tracking_number: tracking_number
    )
  end

  def update_tracking_events
    return if interstellar_tracking.blank?

    interstellar_tracking.shipment_events.each do |shipment_event|
      next if shipment_event.time.blank? || shipment_event.status.blank? ||
              shipment_event.location.blank? ||
              shipment_event.location.city.blank? ||
              shipment_event.location.state.blank?

      fingerprint = Digest::SHA2.hexdigest(
        shipment_event.time +
        shipment_event.status.to_s
      )
      tracking_event = tracking_events.where(interstellar_carrier_fingerprint: fingerprint)&.first
      tracking_event = tracking_events.new if tracking_event.blank?

      event = Event.find_by_active_shipping_code(shipment_event.status.to_s)
      next if event.blank?

      tracking_event.assign_attributes(
        at: DateTime.parse(shipment_event.time),
        city: shipment_event.location.city,
        country_alpha2: shipment_event.location.country_code(:alpha2),
        event: event,
        interstellar_carrier_fingerprint: fingerprint,
        state: shipment_event.location.state
      )

      next unless tracking_event.save

      case tracking_event.event.active_shipping_code
      when 'delivered'
        self.delivered_at = tracking_event.at if delivered_at.blank?
      when 'delivery_appointment_scheduled'
        if shipment_event.message.is_a?(DateTime)
          self.delivery_appointment_at = shipment_event.message
        elsif shipment_event.message.is_a?(Date)
          self.delivery_appointment_on = shipment_event.message
        else
          next
        end
      when 'out_for_delivery'
        self.out_for_delivery_at = tracking_event.at if out_for_delivery_at.blank?
      when 'pending_delivery_appointment'
        self.pending_appointment_since = tracking_event.at if pending_appointment_since.blank?
      when 'picked_up'
        self.picked_up_at = tracking_event.at if picked_up_at.blank?
      end

      if changed?
        self.updated_by = nil # robot
        save
      end

      next unless departed_origin_terminal_at.blank?

      tracking_event = tracking_events.where(
        event: Event.find_by_active_shipping_code('departed')
      ).order(at: :desc).limit(1)&.first

      next if tracking_event.blank?

      # TrackingEvent expects localized format and converts to UTC
      update(
        departed_origin_terminal_at: (tracking_event.at + shipper_address.time_zone.utc_offset.seconds).to_s(:db),
        updated_by: nil
      )
    end

    tracking_events
  end

  def status
    return @status if @status

    @status = ''.dup
    @status = 'New'
    @status = 'Quoted' unless broker_carrier.blank?
    @status = 'Dispatched' unless dispatched_at.blank?
    @status = 'Pickup Scheduled' unless pickup_confirmation.blank?
    @status = 'In Transit' unless picked_up_at.blank?
    @status = 'Pending Delivery Appointment' unless pending_appointment_since.blank?
    @status = 'Delivery Scheduled' if !delivery_appointment_at.blank? || !delivery_appointment_on.blank?
    @status = 'Out for Delivery' unless out_for_delivery_at.blank?
    @status = 'Delivered' unless delivered_at.blank?
    @status = 'Canceled' unless canceled_at.blank?
    @status = "Late — #{@status}" if late?
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
      elsif !deliver_by.blank? && (Date.current > deliver_by)
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
      broker_accessorial = broker_customer.broker_accessorials.where(code: code)
      if broker_accessorial.blank?
        broker_accessorial = broker_customer.broker.broker_accessorials.where(code: code)
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

    @assumed_accessorials = []

    # Airports
    if !receiver_name.blank? && %w[aero aircraft airport aviation avionic hangar].any? do |word|
         receiver_name.downcase.include?(word)
       end
      @assumed_accessorials << Accessorial.find_by_code('DAIR')
    end
    if !shipper_name.blank? && %w[aero aircraft airport aviation avionic hangar].any? do |word|
         shipper_name.downcase.include?(word)
       end
      @assumed_accessorials << Accessorial.find_by_code('PAIR')
    end
    if !receiver_address.types.blank? && (receiver_address.types.include? 'airport')
      @assumed_accessorials << Accessorial.find_by_code('DAIR')
    end
    if !shipper_address.types.blank? && (shipper_address.types.include? 'airport')
      @assumed_accessorials << Accessorial.find_by_code('PAIR')
    end

    # Military bases
    if !receiver_address.types.blank? && (receiver_address.types.include? 'military')
      @assumed_accessorials << Accessorial.find_by_code('DMIL')
    end
    if !shipper_address.types.blank? && (shipper_address.types.include? 'military')
      @assumed_accessorials << Accessorial.find_by_code('PMIL')
    end

    # Residential
    if receiver_address.residential? || accessorial_codes.include?('DRES')
      @assumed_accessorials << Accessorial.find_by_code('DRES')
      @assumed_accessorials << Accessorial.find_by_code('DAPP')
      if items.order(Arel.sql('items.weight / items.quantity DESC')).limit(1).first.weight >= 200
        @assumed_accessorials << Accessorial.find_by_code('DLIF')
      end
    end
    if shipper_address.residential? || accessorial_codes.include?('PRES')
      @assumed_accessorials << Accessorial.find_by_code('PRES')
      @assumed_accessorials << Accessorial.find_by_code('PAPP')
      if items.order(Arel.sql('items.weight / items.quantity DESC')).limit(1).first.weight >= 200
        @assumed_accessorials << Accessorial.find_by_code('PLIF')
      end
    end

    # Restaurant
    @assumed_accessorials << Accessorial.find_by_code('PRST') if shipper_address.restaurant?
    @assumed_accessorials << Accessorial.find_by_code('DRST') if receiver_address.restaurant?

    # Appointment delivery
    if !bol_notes.blank? && (bol_notes.downcase.include? 'must contact')
      @assumed_accessorials << Accessorial.find_by_code('DAPP')
    end

    @assumed_accessorials = @assumed_accessorials.uniq
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
    items.inject([]) { |arr, item| arr << item.api_freight_class(use_forced_freight_class: use_forced_freight_class) }
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
        # Rotate the item if longer that 96 inches
        true_items << if item.long_side > 96
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
      if true_items[i][:l] <= (96 - row_l)
        row_l += true_items[i][:l]
        row_w = true_items[i][:w] if true_items[i][:w] > row_w
        true_items[i][:allocated] = true
        i += 1
      elsif true_items[i][:l] > (96 - row_l)
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

  def broker_bol_valid?
    @broker_bol_valid ||= !broker_bol.blank? && broker_bol_shipment_fingerprint == broker_documents_fingerprint
  end

  def broker_dispatch_sheet_valid?
    @broker_dispatch_sheet_valid ||= !broker_dispatch_sheet.blank? && broker_dispatch_sheet_shipment_fingerprint == broker_documents_fingerprint
  end

  def broker_quote_valid?
    @broker_quote_valid ||= !broker_quote.blank? && broker_quote_shipment_fingerprint == broker_documents_fingerprint
  end

  def accessible_by?(user)
    return false unless user.is_a?(User)

    if user.broker?
      if user.has_role?('dispatch') || user.has_role?('sales_rep')
        return true if broker_customer.blank?

        return user.sales_rep_for?(broker_customer)
      end
    elsif user.customer?
      return broker_customer == user.broker_customer
    end

    false
  end

  # TODO: Move to private
  def build_commissions
    return if broker_customer.blank? || total_cost == Money.new(0) || total_charges == Money.new(0)

    unless commissions.blank?
      if commissions.pluck(:paid).include?(true)
        errors.add(:base, 'Pricing cannot be updated because commission(s) have already been paid')
      else
        commissions.each do |commission|
          commission.mark_for_destruction
        end
      end
    end

    # total_charges, total_cost not yet serialized with pre-save attributes so we call Money.new
    profit = Money.new(total_charges_cents - total_cost_cents)

    broker_customer.broker_customer_sales_reps.find_each do |broker_customer_sales_rep|
      amount = profit * (broker_customer_sales_rep.commission_percent.to_f / 100).round(2)
      commission = commissions.build(
        broker_customer_sales_rep: broker_customer_sales_rep,
        amount: amount
      )
    end
  end

  def to_param
    load_id.to_s
  end

  private

  def pro_or_tracking_carrier_pro_changed?
    pro_changed? || tracking_carrier_pro_changed?
  end

  def remove_tracking_events
    tracking_events.destroy_all
  end

  def validate_applied_rate_association
    return if applied_rate.blank?

    if applied_rate.shipment_fingerprint == fingerprint
      self.carrier_cost = applied_rate.cost
      self.carrier_charge = broker_customer.carrier_charge_calculator(carrier_cost: applied_rate.cost, shipment: self)
      self.broker_carrier = applied_rate.broker_carrier
      self.tracking_carrier = applied_rate.tracking_carrier
      self.quote_id = applied_rate.reference
      self.quoted_delivery_by = applied_rate.transit_days.to_i.business_days.after(pickup_on || DateTime.current)

      unless updated_by.broker_customer.blank?
        total_charges = broker_customer.carrier_charge_calculator(
          carrier_cost: applied_rate.cost,
          shipment: self
        )
        total_charges += broker_accessorials.inject(Money.new(0)) do |_sum, broker_accessorial|
          sum += broker_accessorial.upcharge unless broker_accessorial.upcharge.blank?
        end
        self.total_charges = total_charges
      end
    else
      errors.add(:rate, 'Rate fingerprint and shipment fingerprint do not match')
    end
  end

  # Remove applied_rate when carrier changes
  def remove_applied_rate
    self.applied_rate = nil
  end

  def maybe_create_payment_transaction
    return unless !broker_carrier.blank? && broker_carrier.create_invoice_on_pickup? && payment_transactions.blank?

    payment_transaction = PaymentTransaction.create(
      shipment: self,
      broker: broker,
      broker_carrier:
      broker_carrier,
      created_by: updated_by,
      balance: total_cost,
      paid: total_cost,
      due_on: Date.current + broker_carrier.days_to_pay_after_invoice_date.days,
      pro: pro
    )
  end

  # Fix broker_accessorials when broker_customer changes
  def recalculate_broker_accessorials
    new_broker_accessorials = []
    broker_accessorials.each do |broker_accessorials|
      new_broker_accessorials << broker_customer.eligible_broker_accessorials.find_by_code(broker_accessorials.code)
    end
    self.broker_accessorials = new_broker_accessorials
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

  def maybe_book
    self.booked_at = dispatched_at if booked_at.blank?
  end

  def unbook
    self.booked_at = nil
  end

  def uncancel
    self.canceled_at = nil
  end

  def update_deliver_by_to_out_for_delivery_at
    self.deliver_by = out_for_delivery_at.to_date if deliver_by.blank? && !out_for_delivery_at.blank?
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

  # DateTime sanitization
  def sanitize_datetime(datetime:, time_zone:)
    return if datetime.blank?

    time_zone.local_to_utc ActiveSupport::TimeZone[time_zone.to_s].parse(datetime.to_s)
  end

  def sanitize_pending_appointment_since
    self.pending_appointment_since = sanitize_datetime(
      datetime: pending_appointment_since,
      time_zone: receiver_address.time_zone
    )
  end

  def sanitize_dispatched_at
    self.dispatched_at = sanitize_datetime(
      datetime: dispatched_at,
      time_zone: shipper_address.time_zone
    )
  end

  def sanitize_pickup_driver_assigned_at
    self.pickup_driver_assigned_at = sanitize_datetime(
      datetime: pickup_driver_assigned_at,
      time_zone: shipper_address.time_zone
    )
  end

  def sanitize_pickup_on
    self.pickup_on = sanitize_datetime(
      datetime: pickup_on,
      time_zone: shipper_address.time_zone
    )
  end

  def sanitize_picked_up_at
    self.picked_up_at = sanitize_datetime(
      datetime: picked_up_at,
      time_zone: shipper_address.time_zone
    )
  end

  def sanitize_out_for_delivery_at
    self.out_for_delivery_at = sanitize_datetime(
      datetime: out_for_delivery_at,
      time_zone: receiver_address.time_zone
    )
  end

  def sanitize_delivered_at
    self.delivered_at = sanitize_datetime(
      datetime: delivered_at,
      time_zone: receiver_address.time_zone
    )
  end

  def sanitize_deliver_by
    self.deliver_by = sanitize_datetime(
      datetime: deliver_by,
      time_zone: receiver_address.time_zone
    )
  end

  def sanitize_delivery_appointment_at
    self.delivery_appointment_at = sanitize_datetime(
      datetime: delivery_appointment_at,
      time_zone: receiver_address.time_zone
    )
  end

  def sanitize_delivery_appointment_on
    self.delivery_appointment_on = sanitize_datetime(
      datetime: delivery_appointment_on,
      time_zone: receiver_address.time_zone
    )
  end

  def sanitize_departed_origin_terminal_at
    self.departed_origin_terminal_at = sanitize_datetime(
      datetime: departed_origin_terminal_at,
      time_zone: shipper_address.time_zone
    )
  end

  def sanitize_quoted_delivery_by
    self.quoted_delivery_by = sanitize_datetime datetime: quoted_delivery_by, time_zone: receiver_address.time_zone
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
    UserMailer.new_shipment(self).deliver_now unless quote_only?
  end

  def send_notification
    changed_attributes.keys.each do |key|
      return false if !UserMailer.respond_to?(key) || changes[key][1].blank?

      mailer = UserMailer.send(key, self)
      mailer.deliver_now
    end
  end
end
