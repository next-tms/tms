# == Schema Information
#
# Table name: preferred_broker_carriers
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_customer_id
#   @return []
#
# Indexes
#
#  index_preferred_broker_carriers_on_broker_carrier_id   (broker_carrier_id)
#  index_preferred_broker_carriers_on_broker_customer_id  (broker_customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#
class PreferredBrokerCarrier < ApplicationRecord
  belongs_to :broker_carrier
  belongs_to :broker_customer
end
