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
    association :packaging

    declared_freight_class { [nil, Item::FREIGHT_CLASSES.sample].sample }
    desc { Faker::Lorem.words.map(&:upcase_first).join(' ') }
    hazmat { [true, false].sample }
    nmfc { [nil, rand(1000..9999)].sample }
    quantity { rand(1..5) }
    refrigerated { [true, false].sample }

    l { rand(1..99) }
    w { rand(1..99) }
    h { rand(1..99) }

    weight { rand(1..99) }
  end
end
