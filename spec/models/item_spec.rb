# == Schema Information
#
# Table name: items
#
# @!attribute id
#   @return []
# @!attribute declared_freight_class
#   @return [Float]
# @!attribute desc
#   @return [String]
# @!attribute h
#   @return [Integer]
# @!attribute hazmat
#   @return [Boolean]
# @!attribute l
#   @return [Integer]
# @!attribute nmfc
#   @return [String]
# @!attribute quantity
#   @return [Integer]
# @!attribute refrigerated
#   @return [Boolean]
# @!attribute w
#   @return [Integer]
# @!attribute weight
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute packaging_id
#   @return [Integer]
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_items_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#
require 'rails_helper'

RSpec.describe(Item) do
  describe 'validations' do
    it { is_expected.to(allow_values(nil, '', '12345', '1234-5').for(:nmfc)) }
    it { is_expected.not_to(allow_value('123').for(:nmfc).with_message('is not in the correct format')) }
  end
end
