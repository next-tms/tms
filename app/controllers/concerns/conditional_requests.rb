module ConditionalRequests
  extend ActiveSupport::Concern

  protected

  def last_modified_of(object)
    case object
    when ActiveRecord::Relation
      # The ETag's `cache_version` ("<count>-<:usec timestamp>") already queries MAX(updated_at), minding LIMIT and DISTINCT.
      timestamp = object.cache_version.split('-', 2).second
      Time.find_zone('UTC').strptime(timestamp, '%Y%m%d%H%M%S%N') if timestamp.present?
    when ActiveSupport::TimeWithZone, Time then object
    when Enumerable then object.filter_map { last_modified_of(it) }.max
    else object.try(:updated_at)
    end
  end

  def stale?(*objects, etag: nil, last_modified: nil, **)
    if objects.any? { it.is_a?(Array) && it.any?(ActiveRecord::Base) }
      message = 'Passing an array to `stale?` loads every record into Ruby; pass each object as its own argument instead'
      raise message unless Rails.env.production?

      ActiveSupport.deprecator.warn(message, caller_locations)
    end

    # NOTE: Not `Array.wrap` or `flatten`: both call `to_ary`, which loads a relation.
    objects = objects.flat_map { it.is_a?(Array) ? it : [it] }.compact

    etag ||= objects.presence
    last_modified ||= objects.filter_map { last_modified_of(it) }.max

    super(etag:, last_modified:, **)
  end
end
