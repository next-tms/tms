# == Schema Information
#
# Table name: carriers
# Database name: primary
#
#  id                                  :integer          not null, primary key
#  acts_as_broker                      :boolean          default(FALSE)
#  consider_bol_and_pod_documents_same :boolean          default(FALSE)
#  encrypted_api_key                   :string
#  encrypted_proxy_url                 :string
#  has_traceable_pickup_confirmation   :boolean          default(FALSE)
#  mc_number                           :integer
#  name                                :string
#  scac                                :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  broker_billing_address_id           :bigint
#  check_mailing_address_id            :bigint
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
  class << self
    def ransackable_attributes(auth_object = nil)
      [ 'name', 'scac' ]
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end

  include Companyable

  INTERSTELLAR_CREDENTIAL_TYPE_BROKER_CARRIER_COLUMNS = {
    api: %i[username password],
    api_key: %i[encrypted_api_key],
    website: %i[website_username website_password]
  }.freeze

  # API key belonging to Next TMS
  encrypts :encrypted_api_key
  encrypts :encrypted_proxy_url

  has_many :broker_carriers

  has_many :carrier_areas
  has_many :areas, through: :carrier_areas

  has_many :shipments
  has_many :terminals

  belongs_to :broker_billing_address, class_name: 'Address', optional: true

  # has_many :location_addresses, class_name: 'Address', required: false
  belongs_to :check_mailing_address, class_name: 'Address', optional: true

  accepts_nested_attributes_for :check_mailing_address

  scope :freight_kit_api, -> do
    ids = where(scac: FreightKit::Carriers.all.map(&:scac))
          .select { |record| record.broker_carrier_credential_columns.any? }
          .map(&:id)
    where(id: ids)
  end

  validates :name, uniqueness: true
  validates :mc_number, :scac, uniqueness: { allow_nil: true }

  def bol_requires_tracking_number?
    !!freight_kit_class&.bol_requires_tracking_number?
  end

  # Which `BrokerCarrier` columns are required for FreightKit to communicate with the carrier's API.
  # @return <Boolean>
  def broker_carrier_credential_columns
    return [] if required_freight_kit_credentials.blank?

    columns = required_freight_kit_credentials.map do |freight_kit_credential_type|
      INTERSTELLAR_CREDENTIAL_TYPE_BROKER_CARRIER_COLUMNS[freight_kit_credential_type]
    end

    columns.flatten.compact
  end

  def create_pickup_implemented?
    !!freight_kit_class&.create_pickup_implemented?
  end

  def freight_kit_class
    return if scac.blank?

    @freight_kit_class ||= ::FreightKit.const_get(scac)
  rescue NameError
    nil
  end

  # Whether the carrier considers `Shipment#pickup_confirmation`, `Shipment#pro` to be the same.
  # @return <Boolean>
  def pickup_number_is_tracking_number?
    !!freight_kit_class&.pickup_number_is_tracking_number?
  end

  def required_freight_kit_credentials
    freight_kit_class&.required_credential_types || []
  end
end
