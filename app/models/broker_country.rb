# == Schema Information
#
# Table name: broker_countries
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return []
#
# Indexes
#
#  index_broker_countries_on_country_id  (country_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
class BrokerCountry < ApplicationRecord
  belongs_to :country

  validates :country_id, uniqueness: true
end
