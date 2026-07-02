# == Schema Information
#
# Table name: brokers
#
# @!attribute id
#   @return [Integer]
# @!attribute customer_service_email
#   @return [String]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute phone
#   @return [String]
# @!attribute robot_email
#   @return [String]
# @!attribute address_id
#   @return []
# @!attribute first_load_id
#   @return [Integer]
#
# Indexes
#
#  index_brokers_on_address_id  (address_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#
# @deprecated
class Broker < ApplicationRecord
  class << self
    def companyable_order
      order(:name)
    end
  end

  include ::Instigatable
  include Broker::Instigatable
  include Companyable

  after_create :copy_accessorials_to_broker_accessorials
  after_commit :update_broker_carrier_ignore_bol_requires_tracking_number

  audited

  before_save :unique_countries

  belongs_to :address

  has_many :banks
  has_many :broker_accessorials
  has_many :broker_accessorials, dependent: :destroy
  has_many :broker_carriers
  has_many :broker_countries
  has_many :broker_customers
  has_many :payment_transactions
  has_many :payments
  has_many :shipments
  has_many :users, as: :companyable, dependent: :destroy
  has_many :websites

  has_many :broker_customer_sales_reps, through: :broker_customers
  has_many :carriers, through: :broker_carriers
  has_many :countries, through: :broker_countries
  has_many :customers, through: :broker_customers
  has_many :rates, through: :shipments
  has_many :receivables, through: :shipments

  has_one :stripe_account

  phony_normalize :phone, default_country_code: 'US'

  validates :customer_service_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :customer_service_email, presence: true
  validates :name, presence: true
  validates :phone, presence: true
  validates :time_zone_name, presence: true

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :banks
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :broker_carriers
  accepts_nested_attributes_for :broker_countries, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :broker_customers

  def last_load_id
    shipments.blank? ? first_load_id : shipments.order(load_id: :desc).limit(1).first.load_id
  end

  def broker_for?(user:)
    return false unless user.broker_carrier

    user.broker_carrier.broker == self
  end

  def time_zone
    ActiveSupport::TimeZone.new(time_zone_name)
  end

  def as_freight_kit_location
    FreightKit::Location.new(
      contact: FreightKit::Contact.new(
        company_name: name,
        email: "robot@#{customer_service_email.split("@")[1]}",
      ),
      address1: address.street.sub('Apt', 'Ste'),
      city: address.city,
      postal_code: address.zip_code,
      province: address.region.abbreviation,
      country: ActiveUtils::Country.find(address.country.alpha2_code),
    )
  end

  private

  def normalize_phone(phone_number:, country_code:)
    phone_number&.phony_formatted(normalize: country_code)
  end

  def copy_accessorials_to_broker_accessorials
    Accessorial.all.find_each do |accessorial|
      BrokerAccessorial.create(broker: self, accessorial:, code: accessorial.code, name: accessorial.name)
    end
  end

  def unique_countries
    self.countries = countries.distinct if countries.present?
  end

  def update_broker_carrier_ignore_bol_requires_tracking_number
    return unless saved_change_to_ignore_broker_carrier_bol_requires_tracking_number

    broker_carriers.update_all(ignore_bol_requires_tracking_number: ignore_broker_carrier_bol_requires_tracking_number)
  end
end
