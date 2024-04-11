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
#  idx_on_companyable_id_companyable_type_email_1de3a153e6  (companyable_id,companyable_type,email) UNIQUE
#  index_contacts_on_companyable                            (companyable_type,companyable_id)
#
class Contact < ApplicationRecord
  class << self
    def ransackable_associations(auth_object = nil)
      ['companyable', 'contact_roles', 'user']
    end

    def ransackable_attributes(auth_object = nil)
      ['comments', 'email', 'first_name', 'job_title', 'label', 'last_name']
    end

    def with_any_role(*roles)
      joins(:contact_roles).where(contact_roles: { role: roles })
    end

    def with_role(role)
      joins(:contact_roles).where(contact_roles: { role: })
    end
  end

  include HasCompanyable

  has_many :contact_roles, dependent: :destroy
  has_many :document_preferences, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  has_one :broker_customer_as_receivables_contact,
          class_name: 'BrokerCustomer',
          dependent: :restrict_with_error,
          foreign_key: :receivables_contact_id,
          inverse_of: :receivables_contact

  has_one :user, dependent: :restrict_with_error

  accepts_nested_attributes_for :contact_roles, allow_destroy: true, reject_if: :all_blank

  phony_normalize :mobile_phone, default_country_code: 'US'
  phony_normalize :work_phone, default_country_code: 'US'

  validate :validate_email
  validate :validate_first_name_and_last_name

  validates :email,
            presence: true,
            uniqueness: { scope: %i[companyable_id companyable_type] },
            if: -> { email.present? }

  def any_role?(*any_roles)
    return true if roles.any?(:root)

    roles.intersect?(any_roles)
  end

  def dispatcher?
    role?(:dispatcher)
  end

  def active?
    return true if user.blank?

    !user.deactivated?
  end

  # @return [String, nil]
  def full_name
    return if [first_name, last_name].all?(&:blank?)

    "#{first_name} #{last_name}"
  end

  # @return [String]
  def label
    [full_name, super, job_title].compact_blank&.first || ''
  end

  # @param role [Symbol]
  # @return role [Symbol]
  def add_role(role)
    unless ContactRole.roles.keys.map(&:to_sym).include?(role)
      raise ArgumentError, "role must be one of #{ContactRole.roles.keys.join(", ")} (Symbol)"
    end

    return role if role?(role)

    method = new_record? ? :build : :create!
    contact_roles.public_send(method, role:)

    role
  end

  # @param role [String, Symbol] Role to check
  # @return [Boolean]
  def role?(role)
    return true if roles.any?(:root)

    return true if customer? && role == 'accounts_payable' && companyable.receivables_contact == contact

    (roles + %i[broker customer]).include?(role.to_sym)
  end

  def roles
    contact_roles.pluck(:role).map(&:to_sym)
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
