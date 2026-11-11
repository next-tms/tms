# == Schema Information
#
# Table name: pickup_requests
#
# @!attribute id
#   @return []
# @!attribute accepted_pickup_at
#   @return [Time]
# @!attribute accepted_pickup_on
#   @return [Date]
# @!attribute canceled_at
#   @return [Time]
# @!attribute reschedule_reason
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute created_by_id
#   @return []
#
# Indexes
#
#  index_pickup_requests_on_created_by_id  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
# @!attribute id
#   @return []
# @!attribute accepted_pickup_at
#   @return [Time]
# @!attribute accepted_pickup_on
#   @return [Date]
# @!attribute canceled_at
#   @return [Time]
# @!attribute reschedule_reason
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute created_by_id
#   @return []
#
# Indexes
#
#  index_pickup_requests_on_created_by_id  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
FactoryBot.define { factory(:pickup_request) { accepted_pickup_on { 1.day.from_now.to_date } } }
