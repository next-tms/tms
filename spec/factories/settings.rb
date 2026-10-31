# == Schema Information
#
# Table name: settings
#
# @!attribute id
#   @return []
# @!attribute key
#   @return [String]
# @!attribute value
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_settings_on_key  (key) UNIQUE
#
FactoryBot.define do
  factory :setting do
    key { Faker::Alphanumeric.alpha.downcase }
    value { Faker::Alphanumeric.alpha }
  end
end
