# == Schema Information
#
# Table name: receivables
#
# @!attribute id
#   @return []
# @!attribute authorized_at
#   @return [Time]
# @!attribute due_by
#   @return [Time]
# @!attribute invoiced
#   @return [Boolean]
# @!attribute paid_at
#   @return [Time]
# @!attribute sent_at
#   @return [Time]
# @!attribute total_cents
#   @return [Integer]
# @!attribute total_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute authorized_by_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute accounting_invoice_id
#   @return [String]
# @!attribute sent_by_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_receivables_on_authorized_at     (authorized_at)
#  index_receivables_on_authorized_by_id  (authorized_by_id)
#  index_receivables_on_created_by_id     (created_by_id)
#  index_receivables_on_due_by            (due_by)
#  index_receivables_on_invoiced          (invoiced)
#  index_receivables_on_paid_at           (paid_at)
#  index_receivables_on_sent_by_id        (sent_by_id)
#  index_receivables_on_shipment_id       (shipment_id) UNIQUE
#  index_receivables_on_updated_by_id     (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (authorized_by_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (sent_by_id => users.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class Receivable < ApplicationRecord
  class << self
    # @todo Remove
    delegate :build_from_shipment, to: :new

    def ransackable_attributes(auth_object = nil)
      [ 'balance_cents', 'due_by', 'invoiced', 'sent_at', 'total_cents', 'paid_at' ]
    end

    def ransackable_associations(auth_object = nil)
      [ 'authorized_by', 'broker_customer', 'shipment' ]
    end
  end

  include AccountingSyncable
  include Discussable
  include Suppressible

  accounting_syncs :invoice,
                   match: -> { { document_number: shipment.load_id.to_s } },
                   prepare: lambda { |invoice|
                     broker_customer.create_accounting_customer if broker_customer.accounting_customer_id.blank?
                     invoice.customer_id = broker_customer.accounting_customer_id
                   },
                   columns: -> { { invoiced: true } }

  audited

  after_commit :problematic_shipment_later

  before_save :set_authorized_at
  before_save :set_invoiced
  before_save :set_sent_at
  before_save :set_sent_by

  before_validation :set_balance_and_total

  belongs_to :authorized_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :sent_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  belongs_to :shipment
  has_one :broker_customer, through: :shipment

  has_many :receivable_items, autosave: true, dependent: :destroy

  has_one :broker, through: :shipment

  has_one_attached :invoice

  monetize :balance_cents, allow_nil: false
  monetize :total_cents, allow_nil: false

  scope :authorized, -> { where.not(authorized_at: nil) }
  scope :unauthorized, -> { where.not(id: authorized) }

  scope :invoiced, -> { where.not(invoiced: false) }
  scope :not_invoiced, -> { where.not(id: invoiced) }

  scope :paid, -> { where(balance_cents: 0) }
  scope :unpaid, -> { where.not(balance_cents: 0).where(paid_at: nil) }

  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where.not(id: sent) }

  scope :with_invoice, lambda {
    left_joins(:invoice_attachment)
    .group(:id)
    .having('COUNT(active_storage_attachments) != 0')
  }

  scope :without_invoice, lambda {
    left_joins(:invoice_attachment)
    .group(:id)
    .having('COUNT(active_storage_attachments) = 0')
  }

  validates :due_by, presence: true

  def build_discussable_topic?
    true
  end

  # @todo Move to Shipment#create_receivable
  def build_from_shipment(shipment)
    due_by = (Time.current + 30.days).in_time_zone(shipment.broker.time_zone).end_of_day
    assign_attributes(due_by:, shipment:)

    receivable_items.map(&:mark_for_destruction) if receivable_items.present?

    receivable_items.build(
      charge: shipment.carrier_charge,
      description: shipment.items.map do |item|
        dimensions = [ item.l, item.w, item.h ].all?(&:present?) ? "#{item.l}x#{item.w}x#{item.h}" : ''

        <<~DESC.squish
          #{item.quantity}
          #{item.packaging.name}
          #{item.desc}
          #{dimensions}
          #{item.declared_freight_class.presence || item.calculated_freight_class}
          #{ActionController::Base.helpers.number_with_delimiter(item.weight)} lbs
        DESC
      end.join("\n"),
    )

    shipment.shipment_broker_accessorials.sort_by do |shipment_broker_accessorial|
      shipment_broker_accessorial.broker_accessorial.name
    end.each do |shipment_broker_accessorial|
      next if shipment_broker_accessorial.broker_accessorial.broker_only?

      receivable_items.build(
        charge: shipment_broker_accessorial.charge,
        description: shipment_broker_accessorial.broker_accessorial.name,
      )
    end

    self.total = receivable_items.reject(&:marked_for_destruction?).sum(&:charge)

    self
  end

  def eligible_discussable_contacts
    broker_contact_ids = User.with_role('accounting').broker.pluck(:contact_id) +
                         User.with_role('accounts_receivable').broker.pluck(:contact_id)

    customer_contact_ids = if broker_customer.present?
                             [ broker_customer.receivables_contact.id ] +
                               broker_customer.users.with_role('accounting').pluck(:contact_id) +
                               broker_customer.users.with_role('accounts_payable').pluck(:contact_id)
                           else
                             []
                           end

    # Fallback
    broker_contact_ids = [ User.with_role('root').broker.pluck(:contact_id) ] if broker_contact_ids.empty?

    ids = broker_contact_ids + customer_contact_ids
    Contact.where(id: ids)
  end

  def fetch_invoice
    accounting_invoice_pdf if Accounting.connected?
  end

  # @note For Suppressible
  def suppressed_by_problematic
    shipment
  end

  def update_from_api
    update_from_accounting_invoice if Accounting.connected?
  end

  def missing_carrier_bol?
    return false unless broker_customer.present? && broker_customer.requires_carrier_bol_on_receivables?

    !shipment.carrier_bol.attached?
  end

  def missing_carrier_pod?
    return false unless broker_customer.present? && broker_customer.requires_carrier_pod_on_receivables?

    !shipment.carrier_pod.attached?
  end

  def sendable?
    return false if broker_customer.blank? || shipment.picked_up_at.blank?

    update_from_api if persisted?

    return false if sent? || balance_cents.zero?
    return false unless invoice.attached? || fetch_invoice

    return false if shipment.requires_charges_confirmed_on_receivables? && !shipment.charges_confirmed?

    unless broker_customer.receivables_schedule == 'immediately'
      now = Time.current.in_time_zone(broker_customer.broker.time_zone)

      # Always send batches between 9 PM - 12 AM
      return false if now.hour < 21

      case broker_customer.receivables_schedule
      when 'weekly'
        return false if now.wday.nonzero? # Sunday
      when 'monthly'
        return false unless now.to_date == now.end_of_month.to_date
      end
    end

    if broker_customer.requires_carrier_bol_on_receivables? && broker_customer.requires_carrier_pod_on_receivables?
      documents_attached = [ shipment.carrier_bol.attached?, shipment.carrier_pod.attached? ]

      return documents_attached.any?(true) if shipment.broker_carrier&.carrier&.consider_bol_and_pod_documents_same?

      return documents_attached.all?(true)
    end

    return shipment.carrier_bol.attached? if broker_customer.requires_carrier_bol_on_receivables?

    return shipment.carrier_pod.attached? if broker_customer.requires_carrier_pod_on_receivables?

    true
  end

  def total_changed_externally?
    return false if receivable_items.blank?

    calculated_total = Money.new(0)
    receivable_items.each do |receivable_item|
      next if receivable_item.marked_for_destruction?

      calculated_total += receivable_item.charge
    end

    calculated_total != total
  end

  def sent?
    sent_at.present?
  end

  def accounting_invoice_pdf
    return unless Accounting.connected? && accounting_invoice.present?

    data = accounting_invoice.pdf
    data = (sleep(10) || accounting_invoice.pdf) if data&.include?('errorCode=')
    return if data.blank?

    filename = "#{shipment.load_id} Invoice.pdf"
    path = File.join(Dir.tmpdir, filename)
    File.binwrite(path, data)

    invoice.attach(ActiveStorage::Blob.create_and_upload!(io: File.open(path), filename:, content_type: 'application/pdf'))
    shipment.problematic!
  end

  def update_from_accounting_invoice
    return if accounting_invoice.blank?

    now = Time.current
    update_columns(balance_cents: accounting_invoice.balance.cents)
    update_columns(paid_at: now) if accounting_invoice.balance.zero?
    update_columns(total_cents: accounting_invoice.total.cents)
    update_columns(sent_at: now) if !sent? && (accounting_invoice.balance.zero? || accounting_invoice.email_status == 'EmailSent')

    reload
  end

  def to_accounting_invoice
    time_zone = ActiveSupport::TimeZone.new(Setting.value!(:time_zone_name))

    Accounting::Invoice
    .new(
      billing_address: accounting_billing_address,
      billing_email_address: broker_customer.receivables_contact.email,
      document_number: shipment.load_id.to_s,
      due_date: due_by.in_time_zone(time_zone).to_date,
      line_items: accounting_invoice_line_items,
      ship_date: shipment.picked_up_at.in_time_zone(time_zone).to_date,
      shipping_address: accounting_shipping_address,
      shipping_method: accounting_shipping_method,
      tracking_number: shipment.load_id,
      transaction_date: Time.current.in_time_zone(time_zone),
    )
  end

  private

  def accounting_billing_address
    address = broker_customer.office_address.to_accounting_address
    address.line2 = address.line1
    address.line1 = broker_customer.customer.name
    address
  end

  def accounting_invoice_line_items
    line_items = []

    references = []
    references << "Shipper Ref: #{shipment.shipper_reference}" if shipment.shipper_reference.present?
    references << "PO Ref: #{shipment.customer_reference}" if shipment.customer_reference.present?

    if references.present?
      line_items << Accounting::LineItem.new(description: references.join("\n"))
    end

    unless broker_customer.office_address.proper(', ') == shipment.shipper_address.proper(', ')
      description = <<~PICKUP.strip
        Pickup from:

        #{shipment.shipper_name}
        #{shipment.shipper_address.proper("\n")}
      PICKUP

      line_items << Accounting::LineItem.new(description:)
    end

    receivable_items.each do |receivable_item|
      amount = receivable_item.charge_cents.to_f / 100

      line_items << Accounting::LineItem
                    .new(
                      amount:,
                      description: receivable_item.description,
                      kind: :sales,
                      quantity: 1,
                      unit_price: amount,
                    )
    end

    line_items
  end

  def accounting_shipping_address
    address = shipment.receiver_address.to_accounting_address
    address.line2 = address.line1
    address.line1 = shipment.receiver_name
    address
  end

  def accounting_shipping_method
    carrier =
      if shipment.broker_carrier.blank?
        nil
      elsif shipment.broker_carrier.carrier.acts_as_broker
        shipment.tracking_carrier.presence || shipment.broker_carrier.carrier
      else
        shipment.broker_carrier.carrier
      end

    carrier&.name
  end

  def problematic_shipment_later
    ProblematicJob.perform_later([ shipment.id ], type: 'Shipment')
  end

  def set_authorized_at
    unless authorized_at.blank? && Accounting.connected? && accounting_invoice.present?
      return
    end

    self.authorized_at = accounting_invoice.created_at
  end

  def set_balance_and_total
    return if receivable_items.blank?

    new_balance = Money.new(0)
    receivable_items.each do |receivable_item|
      next if receivable_item.marked_for_destruction?

      new_balance += receivable_item.charge
    end

    self.balance = new_balance
    self.total = new_balance
  end

  def set_invoiced
    return if invoiced?

    self.invoiced = Accounting.connected? && accounting_invoice.present?
  end

  def set_sent_at
    self.sent_at = paid_at if sent_at.blank?
  end

  def set_sent_by
    self.sent_by = nil unless invoiced? && authorized_at.present?
  end
end
