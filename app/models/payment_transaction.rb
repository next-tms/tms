# == Schema Information
#
# Table name: payment_transactions
#
# @!attribute id
#   @return []
# @!attribute additional_charge
#   @return [Boolean]
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute due_on
#   @return [Date]
# @!attribute invoice
#   @return [String]
# @!attribute notes
#   @return [String]
# @!attribute paid_cents
#   @return [Integer]
# @!attribute paid_currency
#   @return [String]
# @!attribute pro
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute legacy_load_id
#   @return [String]
# @!attribute payment_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_payment_transactions_on_broker_carrier_id  (broker_carrier_id)
#  index_payment_transactions_on_payment_id         (payment_id)
#  index_payment_transactions_on_shipment_id        (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (payment_id => payments.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
class PaymentTransaction < ApplicationRecord
  class << self
    def ransackable_attributes(auth_object = nil)
      [ 'id', 'legacy_load_id', 'notes' ]
    end

    def ransackable_associations(auth_object = nil)
      [ 'shipment' ]
    end
  end

  include AccountingSyncable

  accounting_syncs :bill,
                   match: -> { { document_number: shipment.load_id.to_s } },
                   prepare: lambda { |bill|
                     broker_carrier.create_accounting_vendor if broker_carrier.accounting_vendor_id.blank?
                     bill.vendor_id = broker_carrier.accounting_vendor_id
                   }

  after_commit :push_to_accounting

  audited

  before_validation :set_attributes_from_shipment

  belongs_to :created_by, class_name: 'User', optional: true

  belongs_to :payment, optional: true
  belongs_to :shipment, optional: true

  belongs_to :broker
  belongs_to :broker_carrier

  monetize :balance_cents
  monetize :paid_cents

  scope :due, -> { includes(:payment).where(payment: { paid_on: nil }).or(includes(:payment).where(payment: nil)) }
  scope :paid, -> { includes(:payment).where.not(payment: { paid_on: nil }) }

  validates :broker, presence: true
  validates :invoice, presence: true
  validates :shipment, presence: true

  # https://github.com/activerecord-hackery/ransack/issues/224#issuecomment-22818039
  ransacker :id do
    Arel.sql("to_char(\"#{table_name}\".\"id\", '99999999')")
  end

  def duplicates
    return [] if shipment.blank?

    broker_carrier.payment_transactions.where(shipment:) - [ self ]
  end

  def paid?
    !!payment&.paid?
  end

  def shipment_load_id=(load_id)
    self.shipment = Shipment.find_by(load_id:)
  end

  def shipment_load_id
    shipment.blank? ? nil : shipment.load_id
  end

  def variance
    return Money.new(0) if shipment.blank?
    return balance if additional_charge?

    balance - shipment.carrier_cost
  end

  def to_accounting_bill
    Accounting::Bill.new(
      document_number: shipment.load_id.to_s,
      due_date: due_on,
      line_items: [ accounting_bill_line_item ],
      mailing_address: accounting_bill_mailing_address,
      private_note: notes,
    )
  end

  def update_from_accounting_bill
    return if accounting_bill.blank?

    method = persisted? ? :update_columns : :assign_attributes
    send(method, balance_cents: (accounting_bill.balance.to_f * 100).to_i, total_cents: (accounting_bill.total.to_f * 100).to_i)
    send(method, paid_at: DateTime.current) if accounting_bill.balance.zero?

    reload if persisted?
  end

  def update_from_accounting_bill_later = !!FetchPaymentTransactionAccountingBillJob.perform_later(self)

  private

  def accounting_bill_description
    parts = [ "#{Setting.value!(:name)} Load #{shipment.load_id}" ]
    parts << "#{broker_carrier.name} Pro #{shipment.pro}" if shipment.pro.present?

    "Shipping (#{parts.join(' / ')})"
  end

  def accounting_bill_line_item
    Accounting::LineItem.new(amount: paid_cents.to_f / 100, description: accounting_bill_description, kind: :account_based_expense)
  end

  def accounting_bill_mailing_address
    address = broker_carrier.check_mailing_address&.to_accounting_address
    return if address.nil?

    address.line2 = address.line1
    address.line1 = broker_carrier.carrier.name
    address
  end

  def push_to_accounting
    return false unless Accounting.connected?

    !!PushPaymentTransactionToAccountingJob.perform_later(self)
  end

  def set_broker
    return if broker_carrier.blank? || broker.present?

    self.broker = broker_carrier.broker
  end

  def set_invoice
    return if invoice.present?

    self.invoice = shipment&.pro || legacy_load_id
  end

  def set_attributes_from_shipment
    return unless broker_carrier.present? && (shipment.blank? || will_save_change_to_pro?)

    new_shipment = Shipment.where(broker_carrier:).where(pro:)
    self.shipment = new_shipment.first if new_shipment.size == 1

    return if shipment.blank?

    self.broker ||= shipment.broker
    self.broker_carrier = shipment.broker_carrier
    self.invoice = shipment.pro.presence || shipment.load_id if invoice.blank?
    self.paid = balance if shipment.carrier_cost >= balance && !will_save_change_to_paid_cents?
  end
end
