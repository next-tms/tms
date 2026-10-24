module Report::Runnable
  BASE_SCOPES = {
    'BrokerCarrier' => ->(_authorizable) { BrokerCarrier.all },
    'BrokerCustomer' => ->(authorizable) { authorizable.broker_customers },
    'Contact' => ->(_authorizable) { Contact.broker },
    'Receivable' => ->(_authorizable) { Receivable.all },
    'Shipment' => ->(authorizable) { authorizable.shipments }
  }.freeze

  RECORD_TYPES = BASE_SCOPES.keys.freeze

  def date_attributes(authorizable)
    date_columns = record_class.columns.select { |column| column.type.in?(%i[date datetime]) }.map(&:name)
    date_columns & record_class.ransackable_attributes(authorizable)
  end

  def date_range? = date_attribute.present?

  def exporter(authorizable, from: nil, to: nil, limit: nil)
    ExporterService.new(records(authorizable, from:, to:).limit(limit), authorizable:, columns:, headers:)
  end

  def record_class = (record_type.constantize if RECORD_TYPES.include?(record_type))

  def records(authorizable, from: nil, to: nil)
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
