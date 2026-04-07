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

  include Receivable::QuickbooksSyncable

  include Discussable
  include Suppressible

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
    quickbooks_invoice_pdf if broker.intuit_account&.connected?
  end

  # @note For Suppressible
  def suppressed_by_problematic
    shipment
  end

  def update_from_api
    update_from_quickbooks_invoice if broker.intuit_account&.connected?
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

  private

  def problematic_shipment_later
    ProblematicJob.perform_later([ shipment.id ], type: 'Shipment')
  end

  def set_authorized_at
    unless authorized_at.blank? && broker_customer.broker.intuit_account&.connected? && quickbooks_invoice.present?
      return
    end

    self.authorized_at = quickbooks_invoice.meta_data.create_time
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

    self.invoiced = IntuitAccount.connected? && quickbooks_invoice.present?
  end

  def set_sent_at
    self.sent_at = paid_at if sent_at.blank?
  end

  def set_sent_by
    self.sent_by = nil unless invoiced? && authorized_at.present?
  end
end
