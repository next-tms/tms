# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
# @!attribute id
#   @return []
# @!attribute comments
#   @return [String]
# @!attribute email
#   @return [String]
# @!attribute first_name
#   @return [String]
# @!attribute job_title
#   @return [String]
# @!attribute label
#   @return [String]
# @!attribute last_name
#   @return [String]
# @!attribute mobile_phone
#   @return [String]
# @!attribute work_phone
#   @return [String]
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return []
#
# Indexes
#
#  index_contacts_on_broker_carrier_id   (broker_carrier_id)
#  index_contacts_on_broker_customer_id  (broker_customer_id)
#  index_contacts_on_broker_id           (broker_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (broker_id => brokers.id)
#
class Contact < ApplicationRecord
  belongs_to :broker, optional: true
  belongs_to :broker_carrier, optional: true
  belongs_to :broker_customer, optional: true

  has_many :document_preferences

  has_one :user

  phony_normalize :mobile_phone, default_country_code: 'US'
  phony_normalize :work_phone, default_country_code: 'US'

  validates :email, uniqueness: { scope: :broker_customer }

  def full_name
    if first_name.blank? && last_name.blank?
      return read_attribute(:label) if first_name.blank? && last_name.blank? && job_title.blank?

      return job_title
    end

    "#{first_name} #{last_name}"
  end

  def label
    full_name
  end

  private

  def normalize_phone(phone_number:, country_code:)
    phone_number ? phone_number.phony_formatted(normalize: country_code) : nil
  end
end
