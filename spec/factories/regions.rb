# frozen_string_literal: true

# == Schema Information
#
# Table name: regions
#
# @!attribute id
#   @return []
# @!attribute abbreviation
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return []
#
# Indexes
#
#  index_regions_on_abbreviation  (abbreviation)
#  index_regions_on_country_id    (country_id)
#  index_regions_on_name          (name)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
FactoryBot.define do
  factory :region do
    abbreviation { Faker::Address.state_abbr }
    country { create(:country) }
    name { Faker::Address.state }

    after(:build) { |record| record.iso31662 = "#{record.country.alpha2_code}_#{record.abbreviation}" }
  end
end
