# frozen_string_literal: true

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
end
