# == Schema Information
#
# Table name: claims
#
# @!attribute id
#   @return []
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute due_on
#   @return [Date]
# @!attribute total_cents
#   @return [Integer]
# @!attribute total_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_claims_on_due_on       (due_on)
#  index_claims_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#
require 'rails_helper'

RSpec.describe(Claim) { describe('relationships') { it { is_expected.to(have_many(:claim_items).dependent(:destroy)) } } }
