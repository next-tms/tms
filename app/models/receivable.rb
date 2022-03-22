# frozen_string_literal: true

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
# @!attribute quickbooks_invoice_id
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
  scope :unpaid, -> { where.not(balance_cents: 0) }

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

  def self.build_from_shipment(shipment)
    new_receivable = new
    new_receivable.build_from_shipment(shipment)
    new_receivable
  end

  def build_from_shipment(shipment)
    assign_attributes(
      shipment:,
      due_by: (shipment.picked_up_at + 30.days).end_of_day.in_time_zone('America/Los_Angeles')
    )

    receivable_items.map(&:mark_for_destruction) unless receivable_items.blank?

    receivable_items.build(
      charge: shipment.carrier_charge,
      description: shipment.items.map do |item|
        "#{item.quantity} #{item.packaging.name} #{item.desc} #{item.l && item.w && item.h ? "#{item.l}x#{item.w}x#{item.h}" : ''} #{item.forced_freight_class.blank? ? item.calculated_freight_class : item.forced_freight_class} #{ActionController::Base.helpers.number_with_delimiter item.weight} lbs"
      end.join("\n")
    )

    shipment.shipment_broker_accessorials.sort_by do |shipment_broker_accessorial|
      shipment_broker_accessorial.broker_accessorial.name
    end.each do |shipment_broker_accessorial|
      next if shipment_broker_accessorial.broker_accessorial.broker_only?

      receivable_items.build(
        charge: shipment_broker_accessorial.charge,
        description: shipment_broker_accessorial.broker_accessorial.name
      )
    end

    self.total = receivable_items.reject(&:marked_for_destruction?).sum(&:charge)

    self
  end

  def fetch_invoice
    quickbooks_invoice_pdf if broker.intuit_account&.connected?
  end

  def update_from_api
    update_from_quickbooks_invoice if broker.intuit_account&.connected?
  end

  def missing_carrier_bol?
    return false unless shipment.broker_customer.requires_carrier_bol_on_receivables?

    !shipment.carrier_bol.attached?
  end

  def missing_carrier_pod?
    return false unless shipment.broker_customer.requires_carrier_pod_on_receivables?

    !shipment.carrier_pod.attached?
  end

  def sendable?
    return false if broker_customer.blank? || shipment.picked_up_at.blank?

    update_from_api if persisted?

    return false unless paid_at.blank?

    unless invoice.present?
      fetch_invoice

      return false unless invoice.present?
    end

    unless broker_customer.receivables_schedule == 'immediately'
      now = DateTime.current.in_time_zone(broker_customer.broker.time_zone)

      # Always send batches between 9 PM - 12 AM
      return false unless now.hour >= 21

      case broker_customer.receivables_schedule
      when 'weekly'
        return false unless now.wday == 0 # Sunday
      when 'monthly'
        return false unless now.to_date == now.end_of_month.to_date
      end
    end

    if broker_customer.requires_carrier_bol_on_receivables? && broker_customer.requires_carrier_pod_on_receivables?
      return shipment.carrier_bol.present? && shipment.carrier_pod.present?
    end

    return shipment.carrier_bol.present? if broker_customer.requires_carrier_bol_on_receivables?

    return shipment.carrier_pod.present? if broker_customer.requires_carrier_pod_on_receivables?

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

  def create_quickbooks_invoice
    return nil unless broker.intuit_account&.connected?
    return @quickbooks_invoice unless @quickbooks_invoice.blank?

    result = quickbooks_invoice
    return result unless result.blank?

    broker_customer.create_quickbooks_customer if broker_customer.quickbooks_customer.blank?

    result = QuickbooksApiClient::Invoices.new(broker:).create(self)
    return nil if result.blank?

    update_columns(quickbooks_invoice_id: result.id)
    @quickbooks_invoice = result
  end

  def quickbooks_invoice
    return nil unless broker.intuit_account&.connected?
    return @quickbooks_invoice unless @quickbooks_invoice.blank?

    result = nil

    result = QuickbooksApiClient::Invoices.new(broker:).find(quickbooks_invoice_id) unless quickbooks_invoice_id.blank?
    unless result.blank?
      persisted? ? update_columns(quickbooks_invoice_id: result.id) : quickbooks_invoice_id = result.id
      return @quickbooks_invoice = result
    end

    result = QuickbooksApiClient::Invoices.new(broker:).find_by_doc_number(shipment.load_id)
    unless result.blank?
      persisted? ? update_columns(quickbooks_invoice_id: result.id) : quickbooks_invoice_id = result.id
      return @quickbooks_invoice = result
    end

    nil
  end

  def quickbooks_invoice_pdf
    return nil if !broker.intuit_account&.connected? || quickbooks_invoice.blank?

    data = QuickbooksApiClient::Invoices.new(broker:).pdf(quickbooks_invoice)
    return nil if data.blank?

    filename = "#{shipment.load_id} Invoice.pdf"
    path = File.join(Dir.tmpdir, filename)

    File.open(path, 'wb') do |file|
      file.write(data)
    end

    invoice.attach(io: File.open(path), filename:, content_type: 'application/pdf')
  end

  def update_from_quickbooks_invoice
    return if quickbooks_invoice.blank?

    now = DateTime.current

    # Using update_columns so we can bypass the validation that recalculates amounts
    update_columns(balance_cents: Money.new(quickbooks_invoice.balance.to_f * 100))
    update_columns(paid_at: now) if quickbooks_invoice.balance.zero?
    update_columns(sent_at: now) if quickbooks_invoice.email_status == 'EmailSent'
    update_columns(total_cents: Money.new(quickbooks_invoice.total.to_f * 100))
  end

  def update_quickbooks_invoice
    return nil unless broker.intuit_account&.connected?

    # Find existing record if it doesn't exist yet
    if quickbooks_invoice_id.blank? && !quickbooks_invoice.blank?
      update_columns(quickbooks_invoice_id: quickbooks_invoice.id)
      return update_quickbooks_invoice
    end

    if shipment.broker_customer.quickbooks_customer.blank?
      raise "BrokerCustomer id=#{shipment.broker_customer.id} must exist in QuickBooks"
    end

    result = QuickbooksApiClient::Invoices.new(broker:).update(self)
    return nil if result.blank?

    update_columns(quickbooks_invoice_id: result.id, invoiced: true)
    @quickbooks_invoice = result
  end

  private

  def set_authorized_at
    return unless authorized_at.blank?

    if broker_customer.broker.intuit_account&.connected? && !quickbooks_invoice.blank?
      self.authorized_at = quickbooks_invoice.meta_data.create_time
    end
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

    self.invoiced = true if broker_customer.broker.intuit_account&.connected? && !quickbooks_invoice.blank?
  end

  def set_sent_at
    self.sent_at = nil unless invoiced? && !authorized_at.blank?
  end

  def set_sent_by
    self.sent_by = nil unless invoiced? && !authorized_at.blank?
  end
end
