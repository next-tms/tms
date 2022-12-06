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
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
class Carrier < ApplicationRecord
  INTERSTELLAR_CREDENTIAL_TYPE_BROKER_CARRIER_COLUMNS = {
    api: %i[username password],
    api_key: %i[encrypted_api_key],
    website: %i[website_username website_password]
  }.freeze

  # API key belonging to Next TMS
  encrypts :encrypted_api_key

  has_many :broker_carriers
  has_many :brokers, through: :broker_customers

  has_many :carrier_areas
  has_many :areas, through: :carrier_areas

  has_many :shipments
  has_many :terminals

  belongs_to :broker_billing_address, class_name: 'Address', required: false

  # has_many :location_addresses, class_name: 'Address', required: false
  belongs_to :check_mailing_address, class_name: 'Address', required: false

  has_many :carrier_contacts
  has_many :contacts, through: :carrier_contacts

  accepts_nested_attributes_for :check_mailing_address

  validates :name, uniqueness: true
  validates :scac, uniqueness: { allow_nil: true }
  validates :mc_number,
            length: { is: 6 },
            numericality: { only_integer: true },
            uniqueness: { allow_nil: true }

  def bol_requires_tracking_number?
    !!interstellar_class&.bol_requires_tracking_number?
  end

  # Which `BrokerCarrier` columns are required for Interstellar to communicate with the carrier's API.
  # @return <Boolean>
  def broker_carrier_credential_columns
    return [] unless required_interstellar_credentials.present?

    columns = required_interstellar_credentials.map do |interstellar_credential_type|
      INTERSTELLAR_CREDENTIAL_TYPE_BROKER_CARRIER_COLUMNS[interstellar_credential_type]
    end

    columns.flatten.compact
  end

  def create_pickup_implemented?
    !!interstellar_class&.create_pickup_implemented?
  end

  def interstellar_class
    return nil if scac.blank?

    @interstellar_class ||= ::Interstellar.const_get(scac)
  rescue NameError
    nil
  end

  # Whether the carrier considers `Shipment#pickup_confirmation`, `Shipment#pro` to be the same.
  # @return <Boolean>
  def pickup_number_is_tracking_number?
    !!interstellar_class&.pickup_number_is_tracking_number?
  end

  def required_interstellar_credentials
    interstellar_class&.required_credential_types || []
  end
end
