# frozen_string_literal: true

# == Schema Information
#
# Table name: carrier_areas
#
# @!attribute id
#   @return []
# @!attribute carrier_id
#   @return []
# @!attribute from_area_id
#   @return []
# @!attribute to_area_id
#   @return []
#
# Indexes
#
#  index_carrier_areas_on_carrier_id    (carrier_id)
#  index_carrier_areas_on_from_area_id  (from_area_id)
#  index_carrier_areas_on_to_area_id    (to_area_id)
#
# Foreign Keys
#
#  fk_rails_...  (carrier_id => carriers.id)
#  fk_rails_...  (from_area_id => areas.id)
#  fk_rails_...  (to_area_id => areas.id)
#
class CarrierArea < ApplicationRecord
  belongs_to :carrier

  belongs_to :from_area, class_name: 'Area'
  belongs_to :to_area, class_name: 'Area'
end
