class DocumentPolicy < ApplicationPolicy
  CARRIER_NAMES = [
    'broker_bol',
    'broker_carrier_quote',
    'broker_dispatch_sheet',
    'broker_label',
    'carrier_bol',
    'carrier_label',
    'carrier_pod'
  ].freeze
  CUSTOMER_NAMES = ['broker_bol', 'broker_label', 'broker_quote', 'carrier_pod', 'invoice'].freeze

  def view?
    return true if broker?
    return CARRIER_NAMES.include?(record.name) if carrier?

    customer? && CUSTOMER_NAMES.include?(record.name)
  end
end
