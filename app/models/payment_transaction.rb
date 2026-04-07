# frozen_string_literal: true

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

  include PaymentTransaction::QuickbooksSyncable

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

  private

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
