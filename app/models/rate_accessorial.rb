# == Schema Information
#
# Table name: rate_accessorials
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accessorial_id
#   @return []
# @!attribute rate_id
#   @return []
#
# Indexes
#
#  index_rate_accessorials_on_accessorial_id  (accessorial_id)
#  index_rate_accessorials_on_rate_id         (rate_id)
#
# Foreign Keys
#
#  fk_rails_...  (accessorial_id => accessorials.id)
#  fk_rails_...  (rate_id => rates.id)
#
class RateAccessorial < ApplicationRecord
  belongs_to :rate
  belongs_to :accessorial
end
