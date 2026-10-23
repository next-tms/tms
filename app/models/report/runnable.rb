module Report::Runnable
  BASE_SCOPES = {
    'BrokerCarrier' => ->(_authorizable) { BrokerCarrier.all },
    'BrokerCustomer' => ->(authorizable) { authorizable.broker_customers },
    'Contact' => ->(_authorizable) { Contact.broker },
    'Receivable' => ->(_authorizable) { Receivable.all },
    'Shipment' => ->(authorizable) { authorizable.shipments }
  }.freeze

  RECORD_TYPE_ROLES = { 'Receivable' => %i[accounts_receivable] }.freeze
  RECORD_TYPES = BASE_SCOPES.keys.freeze

  def self.record_types(authorizable) = RECORD_TYPES.select { |record_type| record_type_available?(record_type, authorizable) }

  def self.record_type_available?(record_type, authorizable)
    roles = RECORD_TYPE_ROLES[record_type]
    RECORD_TYPES.include?(record_type) && (roles.nil? || authorizable.any_role?(*roles))
  end

  def date_attributes(authorizable)
    date_columns = record_class.columns.select { |column| column.type.in?(%i[date datetime]) }.map(&:name)
    date_columns & record_class.ransackable_attributes(authorizable)
  end

  def date_range? = date_attribute.present?

  def default_date_range(today)
    return [ today.beginning_of_month, today ] if from_days_ago.nil? || to_days_ago.nil?

    [ today - from_days_ago, today - to_days_ago ]
  end

  def exporter(authorizable, from: nil, to: nil, limit: nil)
    ExporterService.new(records(authorizable, from:, to:).limit(limit), authorizable:, columns:, headers:)
  end

  def record_class = (record_type.constantize if RECORD_TYPES.include?(record_type))

  def records(authorizable, from: nil, to: nil)
    return record_class.none unless Report::Runnable.record_type_available?(record_type, authorizable)

    scope = BASE_SCOPES.fetch(record_type).call(authorizable)

    if date_range? && from && to
      time_zone = ActiveSupport::TimeZone.new(Setting.value!(:time_zone_name))
      scope = scope.where(date_attribute => from.in_time_zone(time_zone)..to.in_time_zone(time_zone).end_of_day)
    end

    search = scope.ransack(filters, auth_object: authorizable)
    search.sorts = "#{date_attribute || 'id'} asc" if search.sorts.blank?
    search.result.order(id: :asc)
  end
end
