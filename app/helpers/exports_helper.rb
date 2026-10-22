module ExportsHelper
  def export_column_label(record_class, column, mark_internal: false)
    association, attribute = ExporterService.column_parts(column)
    label = ExporterService.association_model(record_class, association).human_attribute_name(attribute)
    return label if !mark_internal || ExporterService.customer_column?(record_class, column)

    safe_join([ label, ' ', tag.span('Internal', class: 'badge text-bg-warning') ])
  end

  def export_column_id(record_class, name, column)
    [ record_class.model_name.param_key, name.parameterize(separator: '_'), column.parameterize(separator: '_') ].join('_')
  end

  def export_columns_frame_id(record_class, association) = [ 'export-columns', record_class.model_name.param_key, association.parameterize ].join('-')

  def export_modal_id(record_class) = "export-modal-#{record_class.model_name.param_key}"

  def export_hidden_fields = query_hidden_fields(request.query_parameters.except('columns', 'page'))

  def query_hidden_fields(query, namespace = nil)
    safe_join(
      query.to_query(namespace).split('&').map do |pair|
        name, value = pair.split('=', 2).map { |part| CGI.unescape(part.to_s) }
        hidden_field_tag(name, value, id: nil)
      end,
    )
  end
end
