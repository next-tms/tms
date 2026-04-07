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
  data = ActiveUtils::Country::COUNTRIES.find { |country| country[:alpha2] == 'US' }

  factory :country do
    alpha2_code { data[:alpha2] }
    alpha3_code { data[:alpha2] }
    name { data[:name] }
    un_code { data[:numeric] }
  end
end
