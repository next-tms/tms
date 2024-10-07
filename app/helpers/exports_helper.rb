module ExportsHelper
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
