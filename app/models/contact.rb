# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
# @!attribute id
#   @return []
# @!attribute comments
#   @return [String]
# @!attribute companyable_type
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
# @!attribute companyable_id
#   @return []
#
# Indexes
#
#  index_contacts_on_companyable  (companyable_type,companyable_id)
#
class Contact < ApplicationRecord
  include HasCompanyable

  has_many :document_preferences, dependent: :destroy

  has_one :broker_customer_as_receivables_contact,
          class_name: 'BrokerCustomer',
                                                             dependent: :restrict_with_error,
                                                             foreign_key: :receivables_contact_id,
                                                             inverse_of: :receivables_contact

  has_one :user, dependent: :restrict_with_error

  phony_normalize :mobile_phone, default_country_code: 'US'
  phony_normalize :work_phone, default_country_code: 'US'

  validates :email, presence: true, uniqueness: { scope: %i[companyable_id companyable_type] }, if: -> {
                                                                                                      email.present?
                                                                                                    }

  validate :validate_email
  validate :validate_first_name_and_last_name

  # @return [String, nil]
  def full_name
    return nil if [first_name, last_name].all?(&:blank?)

    "#{first_name} #{last_name}"
  end

  # @return [String]
  def label
    [full_name, super, job_title].compact_blank&.first || ''
  end

  private

  def normalize_phone(phone_number:, country_code:)
    phone_number&.phony_formatted(normalize: country_code)
  end

  def validate_email
    return if email.present? || companyable.blank? || !companyable.customer? || companyable.receivables_contact != self

    errors.add(:email, 'cannot be blank')
  end

  def validate_first_name_and_last_name
    return if [first_name, last_name].all?(&:present?) || label.present?

    errors.add(:label, 'required when name is blank')
  end
end
