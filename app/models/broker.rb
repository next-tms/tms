# frozen_string_literal: true

class Broker < ApplicationRecord
  has_many :banks
  has_many :users
  has_many :shipments
  has_many :websites

  has_many :broker_carriers
  has_many :carriers, through: :broker_carriers

  has_many :broker_countries
  has_many :countries, through: :broker_countries
  accepts_nested_attributes_for :broker_countries, allow_destroy: true, reject_if: :all_blank

  has_many :broker_customers
  has_many :customers, through: :broker_customers

  has_many :broker_accessorials
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  belongs_to :address

  validates_presence_of :name
  validates_presence_of :customer_service_email
  validates :customer_service_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_presence_of :phone

  phony_normalize :phone, default_country_code: 'US'

  has_many :broker_accessorials, dependent: :destroy
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  has_many :payments
  has_many :payment_transactions

  after_create :copy_accessorials_to_broker_accessorials
  before_save :unique_countries

  def last_load_id
    shipments.blank? ? first_load_id : shipments.order(load_id: :desc).limit(1).first.load_id
  end

  def broker_for?(user:)
    return false unless user.broker_carrier

    user.broker_carrier.broker == self
  end

  private

  def normalize_phone(phone_number:, country_code:)
    phone_number ? phone_number.phony_formatted(normalize: country_code) : nil
  end

  def copy_accessorials_to_broker_accessorials
    Accessorial.all.each do |accessorial|
      BrokerAccessorial.create(broker: self, accessorial: accessorial, code: accessorial.code, name: accessorial.name)
    end
  end

  def unique_countries
    self.countries = self.countries.distinct unless self.countries.blank?
  end
end
