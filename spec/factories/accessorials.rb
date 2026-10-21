# == Schema Information
#
# Table name: accessorials
#
# @!attribute id
#   @return []
# @!attribute code
#   @return [String]
# @!attribute fee
#   @return [Boolean]
# @!attribute freight_kit_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
FactoryBot.define do
  factory :accessorial do
    sequence(:name) { |number| "Accessorial #{number}" }
    code { 'MyString' }
    freight_kit_code { 'MyString' }
    fee { false }
  end
end
