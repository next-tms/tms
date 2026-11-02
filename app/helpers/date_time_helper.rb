module DateTimeHelper
  def flatpickr_data(options = {})
    data = { controller: 'flatpickr' }

    return data.deep_merge(options[:override]) if options[:override].present?

    data.merge(flatpickr_date_format: 'Y-m-d').deep_merge(options)
  end

  def flatpickr_datetime_data(_datetime, time_zone)
    if time_zone.blank?
      return flatpickr_data
             .deep_merge(
               flatpickr_alt_input: true,
               flatpickr_alt_format: 'Y-m-d h:i K',
               flatpickr_enable_time: true,
               flatpickr_date_format: 'Y-m-dTH:i:00-00:00'
             )
    end

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      message = "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
      raise ArgumentError, message
    end

    formatted_offset = time_zone.formatted_offset

    flatpickr_data.deep_merge(
      flatpickr_alt_input: true,
      flatpickr_alt_format: 'Y-m-d h:i K',
      flatpickr_enable_time: true,
      flatpickr_date_format: "Y-m-dTH:i:00#{formatted_offset}"
    )
  end

  def hours_range(date, start_at, end_at, time_zone)
    return if start_at.blank? || end_at.blank?

    starts_at = hours_on(date, start_at, time_zone)
    ends_at = hours_on(date, end_at, time_zone)

    return safe_join([start_at, '-', end_at], ' ') if starts_at.nil? || ends_at.nil?
    return safe_join([start_at, '-', end_at, tag.small(starts_at.zone)], ' ') if starts_at.zone == ends_at.zone

    safe_join([start_at, tag.small(starts_at.zone), '-', end_at, tag.small(ends_at.zone)], ' ')
  end

  def long_date(date, time_zone)
    return if date.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError, "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    date.in_time_zone(time_zone.name).strftime('%m/%d/%y')
  end

  def maybe_in_time_zone(datetime:, time_zone:)
    return '' if datetime.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError, "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    datetime ? datetime.in_time_zone(time_zone.name).to_s[0..-10] : ''
  end

  def pretty_date(date, time_zone, abbreviation: true)
    return if date.blank? || time_zone.blank?

    format = date.year == Time.current.year ? '%m/%d %a %-l:%M %p' : '%m/%d/%y %a %-l:%M %p'

    parts = [date.in_time_zone(time_zone.name).strftime(format)]
    parts << tag.small(time_zone_abbreviation(time_zone, at: date)) if abbreviation

    safe_join(parts, ' ')
  end

  def short_date(date, time_zone)
    return if date.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError, "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    date.in_time_zone(time_zone).strftime('%m/%d/%y')
  end

  def time(datetime, time_zone = nil)
    return if datetime.blank?

    time_zone ||= current_user&.time_zone || Setting.time_zone

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError, "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    zoned_datetime = datetime.in_time_zone(time_zone)

    time_tag zoned_datetime,
             zoned_datetime.strftime('%b %-d, %Y, %-l:%M %p %Z'),
             data: { controller: 'time', time_time_zone_value: time_zone.tzinfo.name }
  end

  def time_zone_abbreviation(time_zone, at: Time.current)
    raise ArgumentError, 'time_zone must be an ActiveSupport::TimeZone' unless time_zone.is_a?(ActiveSupport::TimeZone)

    at.in_time_zone(time_zone).zone
  end

  def time_zone_options(time_zone_name)
    options = ActiveSupport::TimeZone.all.uniq { |time_zone| time_zone.tzinfo.name }.map { |time_zone| [time_zone.to_s, time_zone.tzinfo.name] }
    return options if time_zone_name.blank? || options.any? { |_label, value| value == time_zone_name }

    [[time_zone_name, time_zone_name], *options]
  end

  private

  def hours_on(date, hours, time_zone)
    return if date.blank? || time_zone.blank?

    time_zone.strptime("#{date.to_date.iso8601} #{hours}", '%Y-%m-%d %I:%M %p')
  rescue ArgumentError
    nil
  end
end
