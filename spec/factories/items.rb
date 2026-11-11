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
FactoryBot.define do
  factory :item do
    association :packaging
    association :shipment

    declared_freight_class { [nil, Item::FREIGHT_CLASSES.sample].sample }
    desc { Faker::Lorem.words.map(&:upcase_first).join(' ') }
    hazmat { [true, false].sample }
    nmfc { [nil, rand(1000..99_999)].sample&.to_s }
    quantity { rand(1..5) }
    refrigerated { [true, false].sample }

    l { rand(1..99) }
    w { rand(1..99) }
    h { rand(1..99) }

    weight { rand(1..99) }
  end
end
