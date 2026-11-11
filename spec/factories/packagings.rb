# == Schema Information
#
# Table name: packagings
#
# @!attribute id
#   @return []
# @!attribute freight_kit_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_freight_kit_type  (freight_kit_type)
#  index_packagings_on_name              (name) UNIQUE
#
# @!attribute id
#   @return []
# @!attribute freight_kit_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_freight_kit_type  (freight_kit_type)
#  index_packagings_on_name              (name) UNIQUE
#
FactoryBot.define do
  factory :packaging do
    name { Faker::Name.name }
    freight_kit_type { 'MyString' }
  end
end
