# frozen_string_literal: true

# == Schema Information
#
# Table name: carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute acts_as_broker
#   @return [Boolean]
# @!attribute has_seperate_website_credentials
#   @return [Boolean]
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute name
#   @return [String]
# @!attribute scac
#   @return [String]
# @!attribute broker_billing_address_id
#   @return []
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
class Carrier < ApplicationRecord
  has_many :broker_carriers
  has_many :brokers, through: :broker_customers

  has_many :carrier_areas
  has_many :areas, through: :carrier_areas

  has_many :shipments

  belongs_to :broker_billing_address, class_name: 'Address', required: false

  # has_many :location_addresses, class_name: 'Address', required: false
  belongs_to :check_mailing_address, class_name: 'Address', required: false

  has_many :carrier_contacts
  has_many :contacts, through: :carrier_contacts

  accepts_nested_attributes_for :check_mailing_address

  def as_interstellar_carrier
    carrier = Interstellar.const_get(scac)
    carrier.new(
      account: nil,
      customer_address: nil,
      customer_email: nil,
      customer_name: nil,
      debug: !Rails.env.production?,
      username: nil,
      password: nil
    )
  rescue StandardError
    nil
  end

  def pickup_number_is_tracking_number?
    return false if as_interstellar_carrier.blank?

    as_interstellar_carrier.pickup_number_is_tracking_number?
  end
end
