# frozen_string_literal: true

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
class Broker < ApplicationRecord
  has_many :banks
  has_many :contacts

  has_many :shipments
  has_many :problems, through: :shipments
  has_many :rates, through: :shipments
  has_many :receivables, through: :shipments

  has_many :users
  has_many :websites

  has_many :broker_carriers
  has_many :carriers, through: :broker_carriers

  has_many :broker_countries
  has_many :countries, through: :broker_countries
  accepts_nested_attributes_for :broker_countries, allow_destroy: true, reject_if: :all_blank

  has_many :broker_customers
  has_many :broker_customer_sales_reps, through: :broker_customers
  has_many :customers, through: :broker_customers

  has_many :broker_accessorials
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  has_one :intuit_account

  belongs_to :address

  validates :customer_service_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :customer_service_email, presence: true
  validates :name, presence: true
  validates :phone, presence: true
  validates :time_zone_name, presence: true

  phony_normalize :phone, default_country_code: 'US'

  has_many :broker_accessorials, dependent: :destroy
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  has_many :payments
  has_many :payment_transactions

  after_create :copy_accessorials_to_broker_accessorials
  before_save :unique_countries

  serialize :time_zone

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

  private

  def normalize_phone(phone_number:, country_code:)
    phone_number ? phone_number.phony_formatted(normalize: country_code) : nil
  end

  def copy_accessorials_to_broker_accessorials
    Accessorial.all.each do |accessorial|
      BrokerAccessorial.create(broker: self, accessorial:, code: accessorial.code, name: accessorial.name)
    end
  end

  def unique_countries
    self.countries = countries.distinct unless countries.blank?
  end
end
