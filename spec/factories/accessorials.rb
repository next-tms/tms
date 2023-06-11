# frozen_string_literal: true

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
# @!attribute interstellar_code
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
    name { 'MyString' }
    code { 'MyString' }
    interstellar_code { 'MyString' }
    fee { false }
  end
end
