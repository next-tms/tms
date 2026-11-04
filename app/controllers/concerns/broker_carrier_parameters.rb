module BrokerCarrierParameters
  extend ActiveSupport::Concern

  ATTRIBUTES = [
    :account_desc,
    :account,
    :accounting_notes,
    :broker_customer_id,
    :create_invoice_on_pickup,
    :customer_id,
    :days_to_pay_after_invoice_date,
    :default_bol_notes,
    :encrypted_ach_account_number,
    :encrypted_ach_bank_name,
    :encrypted_ach_routing_number,
    :encrypted_api_key,
    :ignore_bol_requires_tracking_number,
    :password,
    :username,
    :website_password,
    :website_username,
    { check_mailing_address_attributes: %i[city country_alpha2 id ref region_iso31662 street street2 zip_code] }
  ].freeze

  private

  def broker_carrier_params(*extra) = params.expect(broker_carrier: [*extra, *ATTRIBUTES])
end
