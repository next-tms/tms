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
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute authorized_by_id
#   @return []
# @!attribute created_by_id
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
#  index_receivables_on_shipment_id       (shipment_id)
#  index_receivables_on_updated_by_id     (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (authorized_by_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class Receivable < ApplicationRecord
  before_save :set_authorized_at
  before_save :set_invoiced

  before_validation :set_total

  belongs_to :authorized_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  belongs_to :shipment
  has_one :broker_customer, through: :shipment

  has_many :receivable_items, autosave: true, dependent: :destroy

  has_one :broker, through: :shipment

  monetize :total_cents, allow_nil: false

  scope :authorized, -> { where.not(authorized_at: nil) }
  scope :unauthorized, -> { where.not(id: authorized) }

  scope :invoiced, -> { where.not(invoiced: false) }
  scope :not_invoiced, -> { where.not(id: invoiced) }

  scope :paid, -> { where.not(paid_at: nil) }
  scope :unpaid, -> { where.not(id: paid) }

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
        description: shipment_broker_accessorial.broker_accessorial.name.capitalize
      )
    end

    self
  end

  def missing_carrier_bol?
    return false unless shipment.broker_customer.requires_carrier_bol_on_receivables?

    !shipment.carrier_bol.blank?
  end

  def missing_carrier_pod?
    return false unless shipment.broker_customer.requires_carrier_pod_on_receivables?

    !shipment.carrier_pod.blank?
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
    return @quickbooks_invoice = result unless result.blank?

    result = QuickbooksApiClient::Invoices.new(broker:).find_by_doc_number(shipment.load_id)
    return @quickbooks_invoice = result unless result.blank?

    nil
  end

  def update_quickbooks_invoice
    return nil unless broker.intuit_account&.connected?

    # Find existing record if it doesn't exist yet
    if quickbooks_invoice_id.blank? && !quickbooks_invoice.blank?
      update_columns(quickbooks_invoice_id: quickbooks_invoice.id)
      return update_quickbooks_invoice
    end

    if broker_customer.quickbooks_customer.blank?
      raise "BrokerCustomer id=#{broker_cusotmer.id} must exist in QuickBooks"
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

  def set_invoiced
    return if invoiced?

    self.invoiced = true if broker_customer.broker.intuit_account&.connected? && !quickbooks_invoice.blank?
  end

  def set_total
    return if receivable_items.blank?

    new_total = Money.new(0)
    receivable_items.each do |receivable_item|
      next if receivable_item.marked_for_destruction?

      new_total += receivable_item.charge
    end

    self.total = new_total
  end
end
