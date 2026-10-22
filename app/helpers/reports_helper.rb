module ReportsHelper
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

  def report_internal_columns(report)
    report.columns.reject { |column| ExporterService.customer_column?(report.record_class, column) }
  end

  def report_record_name(record_class) = record_class.model_name.human(count: :other)
end
