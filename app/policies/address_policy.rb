class AddressPolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[].freeze
  CUSTOMER_ATTRIBUTES = %i[city country_alpha2 region_iso31662 street street2 zip_code].freeze

  include AuthorizedAttributablePolicy
end
