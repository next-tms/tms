# frozen_string_literal: true

# == Schema Information
#
# Table name: countries
#
# @!attribute id
#   @return []
# @!attribute alpha2_code
#   @return [String]
# @!attribute alpha3_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute un_code
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
FactoryBot.define do
  factory :country do
    alpha2_code { 'MyString' }
    alpha3_code { 'MyString' }
    name { 'MyString' }
    un_code { 1 }
    updated_at { '2022-06-30 00:15:27' }
  end
end
