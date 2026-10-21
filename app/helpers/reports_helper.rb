module ReportsHelper
  def report_column_label(record_class, column, customer_columns)
    header = ExporterService.column_header(record_class, column)
    return header if customer_columns.include?(column)

    safe_join([ header, ' ', tag.span('Internal', class: 'badge text-bg-warning') ])
  end

  def report_filter_label(record_class, key)
    return 'Sort' if key == 's'
    return key.humanize if record_class.ransackable_scopes(current_user).include?(key)

    attribute = key.dup
    predicate = Ransack::Predicate.detect_and_strip_from_string!(attribute)
    return 'Search' if attribute.include?('_or_')

    [ attribute.humanize, predicate&.humanize&.downcase ].compact.join(' ')
  end

  def report_filter_value(value)
    case value
    when Array then value.join(', ')
    when Hash then value.to_json
    when true, 'true' then 'Yes'
    else value.to_s
    end
  end

  def report_internal_columns(report, customer_columns) = report.columns - customer_columns
  def report_record_name(record_class) = record_class.model_name.human(count: :other)
end
