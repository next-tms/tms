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
class Country < ApplicationRecord
  has_many :broker_countries
  has_many :brokers, through: :broker_countries
  has_many :regions

  validates :alpha2_code, presence: true
  validates :alpha3_code, presence: true
  validates :un_code, presence: true

  def format_address(str)
    return nil if str.blank?

    case alpha2_code
    when 'US'
      StreetAddress::US.parse_address(str).to_s
    end
  end
end
