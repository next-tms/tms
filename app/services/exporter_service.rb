class ExporterService
  CSV_FORMULA_PREFIXES = [ '=', '+', '-', '@', "\t", "\r" ].freeze

  CustomerAudience = Data.define do
    def broker? = false
    def customer? = true
  end

  MAX_ASSOCIATION_DEPTH = 3

  class << self
    def association_model(record_class, association)
      association_path(association).reduce(record_class) { |owner, name| owner.reflect_on_association(name).klass }
    end

    def association_available?(record_class, association, authorizable)
      path = association_path(association)
      return false if path.size > MAX_ASSOCIATION_DEPTH

      path.reduce(record_class) do |owner, name|
        return false unless exportable_associations(owner, authorizable).include?(name)

        owner.reflect_on_association(name).klass
      end

      true
    end

    def association_path(association) = association.to_s.split('.')

    def associations_at(record_class, association, authorizable)
      return [] if association_path(association).size >= MAX_ASSOCIATION_DEPTH

      exportable_associations(association_model(record_class, association), authorizable).map do |name|
        [ association, name ].compact.join('.')
      end
    end

    def available_columns(record_class, authorizable)
      columns_at(record_class, nil, authorizable) +
        associations_at(record_class, nil, authorizable).flat_map { |association| columns_at(record_class, association, authorizable) }
    end

    def column_available?(record_class, column, authorizable)
      association, attribute = column_parts(column)
      return false unless association_available?(record_class, association, authorizable)

      association_model(record_class, association).exportable_attributes(authorizable).include?(attribute)
    end

    def columns_at(record_class, association, authorizable)
      association_model(record_class, association).exportable_attributes(authorizable).map do |attribute|
        [ association, attribute ].compact.join('.')
      end
    end

    def column_header(record_class, column)
      association, attribute = column_parts(column)
      header = association_model(record_class, association).human_attribute_name(attribute)
      return header unless association

      "#{header} (#{association_path(association).map(&:humanize).join(' › ')})"
    end

    def column_parts(column)
      *path, attribute = column.to_s.split('.')
      [ path.join('.').presence, attribute ]
    end

    def customer_column?(record_class, column) = column_available?(record_class, column, CustomerAudience.new)

    def default_columns(record_class, authorizable)
      record_class.authorized_attributes(authorizable) + association_columns(record_class, authorizable, :authorized_attributes)
    end

    def exportable_associations(record_class, authorizable)
      record_class.ransackable_associations(authorizable).select do |association|
        reflection = record_class.reflect_on_association(association)
        !reflection.collection? && !reflection.polymorphic? && reflection.klass.try(:authorized_attributable?)
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
    @columns = (columns&.map(&:to_s) || self.class.default_columns(@record_class, authorizable))
               .uniq
               .select { |column| self.class.column_available?(@record_class, column, authorizable) }
    @records = export_records(records)
  end

  def cache_key = "#{records.cache_key}/#{authorizable.cache_key_with_version}/#{Digest::MD5.hexdigest([ columns, headers ].to_json)}"
  def cache_key_with_version = "#{cache_key}-#{cache_version}"
  def cache_version = Digest::MD5.hexdigest([ versions, ordered_ids, time_zone_setting&.cache_key_with_version ].to_json)

  def data
    records.map do |record|
      columns.each_with_object({}) do |column, row|
        association, attribute = column_parts(column)
        target = association_path(association).reduce(row) { |hash, name| hash[name] ||= {} }

        target[attribute] = value_for(record, column)
      end
    end
  end

  def headers = columns.map { |column| @headers[column] || self.class.column_header(@record_class, column) }
  def rows = records.map { |record| columns.map { |column| value_for(record, column) } }

  def updated_at
    return unless timestamped?

    ([ authorizable.updated_at, time_zone_setting&.updated_at ] + versions.map(&:second)).compact.max
  end

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

  def association_path(association) = self.class.association_path(association)
  def column_model(association) = self.class.association_model(@record_class, association)
  def column_parts(column) = self.class.column_parts(column)
  def csv_value(value) = value.is_a?(String) && value.start_with?(*CSV_FORMULA_PREFIXES) ? "'#{value}" : value

  def export_records(records)
    return records unless records.respond_to?(:preload)

    scoped = records.eager_loading? ? records.unscope(:preload) : records.unscope(:includes, :preload)
    preloads.any? ? scoped.preload(*preloads) : scoped
  end

  def format_enum(value, attribute, model)
    I18n.t("activerecord.enums.#{model.model_name.i18n_key}.#{attribute.pluralize}.#{value}", default: value.to_s.humanize)
  end

  def format_phone(value) = PhonyRails.normalize_number(value, default_country_code: 'US')

  def format_value(value, attribute, model)
    return value if value.blank?
    return format_phone(value) if attribute.include?('phone')
    return format_enum(value, attribute, model) if model.defined_enums.key?(attribute)

    value.try(:format).presence || value
  end

  def link_digest(root, primary_key)
    root_key = "#{root.quoted_table_name}.#{root.primary_key}"
    "MD5(STRING_AGG(#{root_key}::text || ':' || #{primary_key}::text, ',' ORDER BY #{root_key}, #{primary_key}))"
  end

  def ordered_ids
    return [] if unloaded_records.order_values.empty?

    @ordered_ids ||= unloaded_records.distinct(false).pluck(@record_class.primary_key)
  end

  def path_model(path) = path.reduce(@record_class) { |owner, name| owner.reflect_on_association(name).klass }

  def preloads
    columns.group_by { |column| column_parts(column).first }.flat_map do |association, association_columns|
      attributes = association_columns.map { |column| column_parts(column).last }
      model_preloads = column_model(association).exportable_preloads(attributes).flatten
      next model_preloads unless association

      [ association_path(association).reverse.reduce(model_preloads) { |nested, name| { name.to_sym => nested } } ]
    end
  end

  def timestamped?
    version_models.all? { |model| model.column_names.include?('updated_at') } &&
      unloaded_records.joins_values.none? &&
      unloaded_records.left_outer_joins_values.none?
  end

  def time_zone_setting = @time_zone_setting ||= Setting.find_by(key: 'time_zone_name')
  def unloaded_records
    @unloaded_records ||= begin
      unloaded = records.unscope(:eager_load, :includes, :preload)
      records.eager_loading? ? unloaded.left_joins(*records.eager_load_values, *records.includes_values) : unloaded
    end
  end

  def value_for(record, column)
    association, attribute = column_parts(column)
    target = association_path(association).reduce(record) { |owner, name| owner&.public_send(name) }

    format_value(target&.authorized_attribute!(attribute, authorizable), attribute, column_model(association))
  end

  def version(relation, model, root = nil)
    table = model.quoted_table_name
    primary_key = "#{table}.#{model.primary_key}"
    timestamped = model.column_names.include?('updated_at')
    selects = [ "COUNT(#{primary_key})", timestamped ? "MAX(#{table}.updated_at)" : 'NULL' ]
    selects << "MD5(STRING_AGG(#{table}::text, ',' ORDER BY #{primary_key}))" unless timestamped
    selects << link_digest(root, primary_key) if root

    relation.pick(*selects.map { |select| Arel.sql(select) }) || [ 0, nil ]
  end

  def version_models = [ @record_class ] + version_paths.map { |path| path_model(path) }
  def version_paths = association_paths(preloads).uniq

  def versions
    @versions ||= begin
      record_ids = (unloaded_records.limit_value ? unloaded_records.distinct(false) : unloaded_records.unscope(:order)).select(@record_class.primary_key)

      exported = @record_class.unscoped.where(@record_class.primary_key => record_ids)

      [ version(exported, @record_class) ] + version_paths.map do |path|
        joins = path.reverse.reduce { |nested, name| { name => nested } }

        version(exported.joins(joins), path_model(path), @record_class)
      end
    end
  end
end
