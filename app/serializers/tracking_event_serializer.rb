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
