# == Schema Information
#
# Table name: tracking_events
#
# @!attribute id
#   @return []
# @!attribute at
#   @return [Time]
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute interstellar_carrier_fingerprint
#   @return [String]
# @!attribute legacy_time_zone
#   @return [String]
# @!attribute public
#   @return [Boolean]
# @!attribute time_zone_name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute address_id
#   @return []
# @!attribute country_id
#   @return []
# @!attribute event_id
#   @return []
# @!attribute region_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute terminal_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_tracking_events_on_address_id   (address_id)
#  index_tracking_events_on_country_id   (country_id)
#  index_tracking_events_on_event_id     (event_id)
#  index_tracking_events_on_region_id    (region_id)
#  index_tracking_events_on_shipment_id  (shipment_id)
#  index_tracking_events_on_terminal_id  (terminal_id)
#  index_tracking_events_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (region_id => regions.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (terminal_id => terminals.id)
#  fk_rails_...  (user_id => users.id)
#
class TrackingEventSerializer < ActiveModel::Serializer
  attributes :address, :at, :event, :region

  def address
    return nil if object.terminal.blank?

    ActiveModel::SerializableResource.new(object.terminal&.address)
  end

  def at
    {
      utc: {
        iso8604: object.at,
        unix: object.at.to_i
      },
      time_zone: {
        dst: object.at.dst?,
        name: object.time_zone.name,
        utc_offset: object.time_zone.utc_offset
      }
    }
  end

  def event
    ActiveModel::SerializableResource.new(object.event)
  end

  def region
    ActiveModel::SerializableResource.new(object.region)
  end
end
