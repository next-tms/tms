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
# @!attribute week
#   @return [Integer]
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
  scope :unpaid, -> { where(payment_id: nil) }
  scope :paid, -> { where.not(payment_id: nil) }

  before_create :set_payment
  before_create :set_week

  before_save :set_shipment

  belongs_to :created_by, class_name: 'User', optional: true

  belongs_to :payment, optional: true
  belongs_to :shipment, optional: true

  belongs_to :broker
  belongs_to :broker_carrier

  monetize :balance_cents
  monetize :paid_cents

  def shipment_load_id=(load_id)
    self.shipment = Shipment.find_by_load_id(load_id)
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

  def set_payment
    payment = Payment.unpaid.where(broker_carrier: broker_carrier).where(week: week)
    if payment.blank?
      payment = Payment.new
      payment.broker = broker
      payment.broker_carrier = broker_carrier
      payment.created_by = created_by
      payment.due_on = due_on
      payment.week = week
      payment.save
    else
      payment = payment.first
    end
    self.payment = payment
  end

  def set_shipment
    shipment = Shipment.where(broker_carrier: broker_carrier).where(pro: pro)
    if shipment.size == 1
      shipment = shipment.first
      self.shipment = shipment
      self.broker_carrier = shipment.broker_carrier
      self.paid = balance if shipment.carrier_cost >= balance
    end
  end

  def set_week
    return if due_on.blank?

    self.week = due_on.strftime('%U').to_i + 1
  end
end
