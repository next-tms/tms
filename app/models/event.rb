# == Schema Information
#
# Table name: events
#
# @!attribute id
#   @return []
# @!attribute active_shipping_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute public_by_default
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
class Event < ApplicationRecord
end
