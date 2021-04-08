# frozen_string_literal: true

class BrokerCarrier < ApplicationRecord
  scope :api_configured, -> { where.not(account: nil).where.not(username: nil).where.not(password: nil) }
  scope :blanket, -> { where(broker_customer: nil) }

  belongs_to :carrier
  belongs_to :broker
  belongs_to :broker_customer, required: false, optional: true

  belongs_to :check_mailing_address, class_name: 'Address', required: false

  has_many :carrier_contacts
  has_many :contacts, through: :carrier_contacts

  has_many :overlength_rules
  has_many :payment_transactions
  has_many :pricing_rules
  has_many :shipments

  accepts_nested_attributes_for :check_mailing_address
  accepts_nested_attributes_for :contacts
  accepts_nested_attributes_for :overlength_rules
  accepts_nested_attributes_for :pricing_rules

  monetize :quote_padding_cents

  def overlength_rules
    if !as_reactive_shipping_carrier.blank? && !as_reactive_shipping_carrier.rates_with_excessive_length_fees
      super
    else
      OverlengthRule.none
    end
  end

  def broker_customer_specific_name
    if broker_customer.blank?
      carrier.name
    else
      "#{carrier.name} - #{broker_customer.customer.name}"
    end
  end

  # HyperCarrier
  def as_reactive_shipping_carrier
    carrier = HyperCarrier.const_get(self.carrier.scac)
    carrier = carrier.new(
      account: account,
      customer_address: {
        street: broker.address.street.sub('Apt', 'Ste'),
        city: broker.address.city,
        state: broker.address.state,
        zip_code: broker.address.zip_code
      },
      customer_email: "robot@#{broker.customer_service_email.split('@')[1]}",
      customer_name: broker.name,
      debug: !Rails.env.production?,
      username: username,
      password: password
    )
    carrier
  rescue StandardError
    nil
  end
end
