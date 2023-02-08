# frozen_string_literal: true

# == Schema Information
#
# Table name: carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute acts_as_broker
#   @return [Boolean]
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute has_seperate_website_credentials
#   @return [Boolean]
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute name
#   @return [String]
# @!attribute scac
#   @return [String]
# @!attribute broker_billing_address_id
#   @return []
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
require 'rails_helper'

RSpec.describe(Carrier, type: :model) do
  describe 'relationships' do
    it { is_expected.to(have_many(:broker_carriers)) }
    it { is_expected.to(have_many(:carrier_areas)) }
    it { is_expected.to(have_many(:terminals)) }

    it { is_expected.to(belong_to(:broker_billing_address).required(false)) }
    it { is_expected.to(belong_to(:check_mailing_address).required(false)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:scac).allow_nil) }

    it { is_expected.to(validate_uniqueness_of(:mc_number).allow_nil) }
    it { is_expected.to(validate_length_of(:mc_number).is_equal_to(6)) }
    it { is_expected.to(validate_numericality_of(:mc_number).only_integer) }
  end
end
