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
# @!attribute broker_id
#   @return []
# @!attribute country_id
#   @return []
#
# Indexes
#
#  index_broker_countries_on_broker_id   (broker_id)
#  index_broker_countries_on_country_id  (country_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
class BrokerCountry < ApplicationRecord
  belongs_to :broker
  belongs_to :country
end
