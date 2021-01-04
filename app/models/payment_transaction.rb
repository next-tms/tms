# frozen_string_literal: true

class PaymentTransaction < ApplicationRecord
  scope :unpaid, -> { where(payment_id: nil) }
  scope :paid, -> { where.not(payment_id: nil) }

  belongs_to :created_by, class_name: 'User', optional: true

  belongs_to :payment, optional: true
  belongs_to :shipment, optional: true

  belongs_to :broker
  belongs_to :broker_carrier

  monetize :balance_cents
  monetize :paid_cents

  after_save :touch_payment

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

  def set_payment
    payment = Payment.unpaid.where(broker_carrier: broker_carrier).where(week: week)
    if payment.blank?
      payment = Payment.new
      payment.broker = broker
      payment.broker_carrier = broker_carrier
      payment.created_by = created_by
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

  private

  # Triggers save on Payment which updated the paid_cents column
  def touch_payment
    unless payment.blank?
      payment = self.payment
      payment.updated_at = DateTime.current
      payment.save
    end
  end
end
