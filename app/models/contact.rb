# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :broker, optional: true
  belongs_to :broker_carrier, optional: true
  belongs_to :broker_customer, optional: true

  phony_normalize :mobile_phone, default_country_code: 'US'
  phony_normalize :work_phone, default_country_code: 'US'

  def full_name
    "#{first_name} #{last_name}"
  end

  def label
    @label ||= read_attribute(:label) || "#{first_name} #{last_name}"
  end

  private

  def normalize_phone(phone_number:, country_code:)
    phone_number ? phone_number.phony_formatted(normalize: country_code) : nil
  end
end
