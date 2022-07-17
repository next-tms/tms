# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
FactoryBot.define do
  factory :role do
    name { 'MyString' }
    updated_at { '2022-07-07 23:37:17' }
  end
end
