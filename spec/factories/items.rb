# frozen_string_literal: true

# == Schema Information
#
# Table name: items
#
# @!attribute id
#   @return []
# @!attribute desc
#   @return [String]
# @!attribute forced_class
#   @return [Float]
# @!attribute h
#   @return [Integer]
# @!attribute hazmat
#   @return [Boolean]
# @!attribute l
#   @return [Integer]
# @!attribute nmfc
#   @return [Integer]
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
#
FactoryBot.define do
  factory :item do
    l { 1 }
    w { 1 }
    h { 1 }
    nmfc { 1 }
    hazmat { false }
    refrigerated { false }
    desc { 'MyString' }
    packaging { create(:packaging) }
    weight { 1 }
    quantity { 1 }
    forced_class { 1.5 }
  end
end
