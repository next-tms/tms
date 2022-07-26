# == Schema Information
#
# Table name: notifications
#
# @!attribute id
#   @return []
# @!attribute params
#   @return [Hash]
# @!attribute read_at
#   @return [Time]
# @!attribute recipient_type
#   @return [String]
# @!attribute type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute recipient_id
#   @return []
#
# Indexes
#
#  index_notifications_on_read_at    (read_at)
#  index_notifications_on_recipient  (recipient_type,recipient_id)
#
class Notification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
end
