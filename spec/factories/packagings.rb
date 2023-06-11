# frozen_string_literal: true

# == Schema Information
#
# Table name: packagings
#
# @!attribute id
#   @return []
# @!attribute interstellar_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_interstellar_type  (interstellar_type)
#
FactoryBot.define do
  factory :packaging do
    name { Faker::Name.name }
    interstellar_type { 'MyString' }
  end
end
