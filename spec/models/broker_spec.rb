# frozen_string_literal: true

# == Schema Information
#
# Table name: brokers
#
# @!attribute id
#   @return [Integer]
# @!attribute automatically_authorize_receivables
#   @return [Boolean]
# @!attribute automatically_update_shipment_tracking_based_on_carrier_apis
#   @return [Boolean]
# @!attribute customer_service_email
#   @return [String]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute ignore_broker_carrier_bol_requires_tracking_number
#   @return [Boolean]
# @!attribute name
#   @return [String]
# @!attribute phone
#   @return [String]
# @!attribute requires_charges_confirmed_on_receivables
#   @return [Boolean]
# @!attribute robot_email
#   @return [String]
# @!attribute theme_primary_color
#   @return [String]
# @!attribute theme_sidebar_background_color
#   @return [String]
# @!attribute theme_sidebar_text_color
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute uuid
#   @return [String]
# @!attribute address_id
#   @return []
# @!attribute first_load_id
#   @return [Integer]
#
# Indexes
#
#  index_brokers_on_address_id  (address_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#
require 'rails_helper'

RSpec.describe(Broker) do
  it_behaves_like 'companyable'
end
