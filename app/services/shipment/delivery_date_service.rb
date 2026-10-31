class Shipment::DeliveryDateService
  delegate(*%i[
             receiver_address
             promised_delivery_by
             delivery_appointment_at
             delivery_appointment_on
             delivery_eta_on
             delivery_hours_start_at
             delivery_hours_end_at
             pickup_from
             pickup_by
           ], to: :shipment)

  attr_reader :shipment, :type

  def initialize(shipment:)
    @shipment = shipment
  end

  def delivery_from
    @type = :delivery_from
    delivery_date
  end

  def delivery_by
    @type = :delivery_by
    delivery_date
  end

  private

  def delivery_date
    tz = receiver_address&.time_zone
    return if tz.blank?

    from = promised_delivery_by.presence || delivery_appointment_at.presence || delivery_appointment_on.presence || delivery_eta_on.presence
    return from if from.present? && !from.is_a?(Date)

    if from.is_a?(Date)
      return from.in_time_zone(tz).beginning_of_day + hours_interval if delivery_hours.blank?

      formatted_offset = Time.current.in_time_zone(tz).formatted_offset
      return Time.zone.parse("#{from} #{delivery_hours} #{formatted_offset}")
    end

    return 5.business_days.after(pickup_date.in_time_zone(tz)).beginning_of_day + hours_interval if pickup_date.present?

    nil
  end

  def pickup_date
    @pickup_date ||= type == :delivery_from ? pickup_from : pickup_by
  end

  def hours_interval
    @hours_interval ||= type == :delivery_from ? 9.hours : 17.hours
  end

  def delivery_hours
    @delivery_hours ||= type == :delivery_from ? delivery_hours_start_at : delivery_hours_end_at
  end
end

## Previous Logic: Todo: Remove after regression testing

# def delivery_from
#   tz = receiver_address&.time_zone
#   return if tz.blank?

#   from = promised_delivery_by.presence || delivery_appointment_at.presence || delivery_appointment_on.presence || delivery_eta_on.presence
#   return from if from.present? && !from.is_a?(Date)

#   if from.is_a?(Date)
#     return from.in_time_zone(tz).beginning_of_day + 9.hours if delivery_hours_start_at.blank?

#     formatted_offset = Time.current.in_time_zone(tz).formatted_offset
#     return Time.zone.parse("#{from} #{delivery_hours_start_at} #{formatted_offset}")
#   end

#   return 5.business_days.after(pickup_from.in_time_zone(tz)).beginning_of_day + 9.hours if pickup_from.present?

#   nil
# end

# def delivery_by
#   tz = receiver_address&.time_zone
#   return if tz.blank?

#   by = promised_delivery_by.presence || delivery_appointment_at.presence || delivery_appointment_on.presence || delivery_eta_on.presence
#   return by if by.present? && !by.is_a?(Date)

#   if by.is_a?(Date)
#     return by.in_time_zone(tz).beginning_of_day + 17.hours if delivery_hours_end_at.blank?

#     formatted_offset = Time.current.in_time_zone(tz).formatted_offset
#     return Time.zone.parse("#{by} #{delivery_hours_end_at} #{formatted_offset}")
#   end

#   return 5.business_days.after(pickup_by.in_time_zone(tz)).beginning_of_day + 17.hours if pickup_by.present?

#   nil
# end
