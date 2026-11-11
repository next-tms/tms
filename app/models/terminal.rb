# == Schema Information
#
# Table name: terminals
#
# @!attribute id
#   @return []
# @!attribute phone
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute address_id
#   @return []
# @!attribute carrier_id
#   @return []
#
# Indexes
#
#  index_terminals_on_address_id  (address_id)
#  index_terminals_on_carrier_id  (carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (carrier_id => carriers.id)
#
# @!attribute id
#   @return []
# @!attribute phone
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute address_id
#   @return []
# @!attribute carrier_id
#   @return []
#
# Indexes
#
#  index_terminals_on_address_id  (address_id)
#  index_terminals_on_carrier_id  (carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (carrier_id => carriers.id)
#
class Terminal < ApplicationRecord
  class << self
    def ransackable_associations(_auth_object = nil)
      ['address', 'carrier']
    end
  end

  belongs_to :address
  belongs_to :carrier

  phony_normalize :phone, default_country_code: 'US'
end
