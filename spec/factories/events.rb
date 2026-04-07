# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
# @!attribute id
#   @return []
# @!attribute active_shipping_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute public_by_default
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
FactoryBot.define do
  factory :event do
    name { Faker::Verb.past_participle.snakecase }
    public_by_default { [ true, false ].sample }

    after(:build) { |record| record.active_shipping_code = record.name }
  end
end
