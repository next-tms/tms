class ExporterService
  CSV_FORMULA_PREFIXES = [ '=', '+', '-', '@', "\t", "\r" ].freeze

  CustomerAudience = Data.define do
    def broker? = false
    def customer? = true
  end

  class << self
    def available_columns(record_class, authorizable)
      record_class.exportable_attributes(authorizable) + association_columns(record_class, authorizable, :exportable_attributes)
    end

    def column_header(record_class, column)
      association, attribute = column_parts(column)
      return record_class.human_attribute_name(attribute) unless association

      "#{record_class.reflect_on_association(association).klass.human_attribute_name(attribute)} (#{association.humanize})"
    end

    def column_parts(column)
      association, attribute = column.to_s.split('.', 2)
      attribute ? [ association, attribute ] : [ nil, association ]
    end

    def customer_columns(record_class) = available_columns(record_class, CustomerAudience.new)

    def default_columns(record_class, authorizable)
      record_class.ransackable_attributes(authorizable) + association_columns(record_class, authorizable, :ransackable_attributes)
    end

    def exportable_associations(record_class, authorizable)
      record_class.ransackable_associations(authorizable).select do |association|
        reflection = record_class.reflect_on_association(association)
        !reflection.polymorphic? && reflection.klass.try(:authorized_attributable?)
      end
    end

    def to_csv(...) = new(...).to_csv
    def to_json(...) = new(...).to_json
    def to_yaml(...) = new(...).to_yaml

    private

    def association_columns(record_class, authorizable, attributes_method)
      exportable_associations(record_class, authorizable).flat_map do |association|
        record_class
          .reflect_on_association(association)
          .klass
          .public_send(attributes_method, authorizable)
          .map { |attribute| "#{association}.#{attribute}" }
      end
    end
  end

  attr_reader :authorizable, :columns, :records

  def initialize(records, authorizable:, columns: nil, headers: {})
    raise ArgumentError, 'authorizable cannot be blank' if authorizable.blank?

    @authorizable = authorizable
    @headers = headers.transform_keys(&:to_s)
    @record_class = records.respond_to?(:klass) ? records.klass : records.first.class
    @columns = (columns&.map(&:to_s) || self.class.default_columns(@record_class, authorizable)) &
               self.class.available_columns(@record_class, authorizable)
    @records = records.respond_to?(:preload) && preloads.any? ? records.preload(*preloads) : records
  end

  def cache_key = "#{records.cache_key}/#{authorizable.cache_key_with_version}/#{Digest::MD5.hexdigest(headers.to_json)}"
  def cache_key_with_version = "#{cache_key}-#{cache_version}"
  def cache_version = Digest::MD5.hexdigest(versions.to_json)

  def data
    records.map do |record|
      columns.each_with_object({}) do |column, row|
        association, attribute = column_parts(column)
        value = value_for(record, column)

        association ? (row[association] ||= {})[attribute] = value : row[attribute] = value
      end
    end
  end

  def headers = columns.map { |column| @headers[column] || self.class.column_header(@record_class, column) }
  def rows = records.map { |record| columns.map { |column| value_for(record, column) } }

  def updated_at = ([ authorizable.updated_at ] + versions.map(&:second)).compact.max

  def to_csv
    CSV.generate(force_quotes: true) do |csv|
      csv << headers
      rows.each { |row| csv << row.map { |value| csv_value(value) } }
    end
  end

  def to_json(*args) = data.to_json(*args)
  def to_yaml = data.to_yaml

  private

  def association_paths(preload, prefix = [])
    case preload
    when Array then preload.flat_map { |nested| association_paths(nested, prefix) }
    when Hash then preload.flat_map { |name, nested| [ prefix + [ name ] ] + association_paths(nested, prefix + [ name ]) }
    else [ prefix + [ preload ] ]
    end
  end

  def column_model(association)
    association ? @record_class.reflect_on_association(association).klass : @record_class
  end

  def column_parts(column) = self.class.column_parts(column)
  def csv_value(value) = value.is_a?(String) && value.start_with?(*CSV_FORMULA_PREFIXES) ? "'#{value}" : value

  def format_enum(value, attribute, model)
    I18n.t("activerecord.enums.#{model.model_name.i18n_key}.#{attribute.pluralize}.#{value}")
  end

  def format_phone(value) = PhonyRails.normalize_number(value, default_country_code: 'US')

  def format_value(value, attribute, model)
    return value if value.blank?
    return format_phone(value) if attribute.include?('phone')
    return format_enum(value, attribute, model) if model.defined_enums.key?(attribute)

    value.try(:format).presence || value
  end

  def preloads
    columns.group_by { |column| column_parts(column).first }.flat_map do |association, association_columns|
      attributes = association_columns.map { |column| column_parts(column).last }
      model_preloads = column_model(association).exportable_preloads(attributes).flatten

      association ? [ { association.to_sym => model_preloads } ] : model_preloads
    end
  end

  def value_for(record, column)
    association, attribute = column_parts(column)
    target = association ? record.public_send(association) : record

    format_value(target&.authorized_attribute!(attribute, authorizable), attribute, column_model(association))
  end

  def version(relation, model)
    table = model.quoted_table_name
    count = "COUNT(#{table}.#{model.primary_key})"
    return relation.pick(Arel.sql(count), Arel.sql("MAX(#{table}.updated_at)")) if model.column_names.include?('updated_at')

    relation.pick(Arel.sql(count), Arel.sql('NULL'), Arel.sql("MD5(STRING_AGG(#{table}::text, ',' ORDER BY #{table}.#{model.primary_key}))"))
  end

  def versions
    @versions ||= begin
      unloaded_records = records.unscope(:eager_load, :includes, :order, :preload)
      record_ids = unloaded_records.select(@record_class.primary_key)

      [ version(unloaded_records, @record_class) ] + association_paths(preloads).uniq.map do |path|
        model = path.reduce(@record_class) { |owner, name| owner.reflect_on_association(name).klass }
        joins = path.reverse.reduce { |nested, name| { name => nested } }

        version(@record_class.unscoped.where(@record_class.primary_key => record_ids).joins(joins), model)
      end
    end
  end
end
