class BrokerCarrier < ApplicationRecord
  class << self
    def companyable_order = joins(:carrier).merge(Carrier.order(:name))
    def ransackable_associations(auth_object = nil) = ['broker_customer', 'carrier'] - private_associations(auth_object)
  end

  include AccountingSyncable

  CREDENTIAL_TYPE_COLUMNS = {
    api: %i[username password],
    api_key: %i[encrypted_api_key],
    website: %i[website_username website_password]
  }.freeze

  accounting_syncs :vendor, match: -> { { name: carrier.name } }

  audited

  belongs_to :broker_customer, optional: true
  belongs_to :carrier
  belongs_to :check_mailing_address, class_name: 'Address', optional: true

  delegate :acts_as_broker?, :pickup_number_is_tracking_number?, :scac, to: :carrier

  encrypts :encrypted_ach_account_number
  encrypts :encrypted_ach_bank_name
  encrypts :encrypted_ach_routing_number
  encrypts :encrypted_api_key

  has_many :overlength_rules, dependent: :destroy
  has_many :payments, dependent: :restrict_with_error
  has_many :payment_transactions, dependent: :restrict_with_error
  has_many :preferred_by_broker_customers, class_name: 'PreferredBrokerCarrier', dependent: :destroy
  has_many :pricing_rules, dependent: :destroy
  has_many :rates, dependent: :restrict_with_error
  has_many :shipments, dependent: :restrict_with_error
  has_many :terminals, through: :carrier

  has_many :pickups, through: :rates

  monetize :quote_padding_cents

  normalizes :encrypted_ach_account_number, :encrypted_ach_bank_name, :encrypted_ach_routing_number, with: ->(value) { value.squish }

  scope :api_configured, -> { where(id: joins(:carrier).merge(Carrier.with_api).select(&:api_configured?).map(&:id)) }
  scope :api_unconfigured, -> { where.not(id: api_configured.ids) }
  scope :blanket, -> { where(broker_customer: nil) }

  validates :encrypted_ach_routing_number, allow_blank: true, format: { with: /\A\d{9}\z/ }

  accepts_nested_attributes_for :check_mailing_address
  accepts_nested_attributes_for :overlength_rules, allow_destroy: true
  accepts_nested_attributes_for :pricing_rules, allow_destroy: true

  def ach? = encrypted_ach_account_number.present? && encrypted_ach_routing_number.present?
  def api_configured? = carrier.required_credential_types.any? && credential_columns.all? { |column| public_send(column).present? }
  def bol_requires_tracking_number? = !ignore_bol_requires_tracking_number && !!carrier.bol_requires_tracking_number?
  def broker_customer_specific_name = broker_customer.blank? ? carrier.name : "#{carrier.name} - #{broker_customer.customer.name}"
  alias name broker_customer_specific_name

  def credential_columns = CREDENTIAL_TYPE_COLUMNS.values_at(*carrier.required_credential_types).compact.flatten
  def find_or_build_check_mailing_address = self.check_mailing_address ||= imported_check_mailing_address || Address.new

  def imported_check_mailing_address
    accounting_vendor&.billing_address&.to_address(Setting.mailing_address!.country_alpha2) ||
      carrier.transponder_check_mailing_addresses&.first&.to_address
  end

  def payable_check_mailing_address = check_mailing_address || imported_check_mailing_address

  def to_accounting_vendor
    Accounting::Vendor.new(
      billing_address: payable_check_mailing_address&.to_accounting_address,
      company_name: carrier.legal_name.presence || carrier.name,
      display_name: carrier.name
    )
  end
end
