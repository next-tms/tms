class ExporterService
  class << self
    def to_csv(...) = new(...).to_csv
    def to_json(...) = new(...).to_json
    def to_yaml(...) = new(...).to_yaml
  end

  attr_reader :authorizable, :records

  def initialize(records, authorizable:)
    raise ArgumentError, 'authorizable cannot be blank' if authorizable.blank?

    @authorizable = authorizable
    @record_class = records.respond_to?(:klass) ? records.klass : records.first.class
    @records = records.respond_to?(:preload) ? records.preload(*exportable_associations) : records
  end

  def cache_key = "#{records.cache_key}/#{authorizable.cache_key_with_version}"

  def data
    records.map do |record|
      row = attributes.index_with { |attribute| format_value(record.authorized_attribute!(attribute, authorizable), attribute) }
      exportable_associations.each do |association|
        associated_record = record.public_send(association)
        row[association.to_s] = association_attributes(association).index_with do |attribute|
          format_value(associated_record&.authorized_attribute!(attribute, authorizable), attribute)
        end
      end
      row
    end
  end

  def updated_at
    timestamps = [ records.maximum(:updated_at), authorizable.updated_at ]
    exportable_associations.each do |association|
      reflection = @record_class.reflect_on_association(association)
      timestamps << association_model(association).where(id: records.select(reflection.foreign_key)).maximum(:updated_at)
    end
    timestamps.compact.max
  end

  def to_csv
    CSV.generate(force_quotes: true) do |csv|
      csv << headers
      records.each { |record| csv << row_for(record) }
    end
  end

  def to_json(*args) = data.to_json(*args)
  def to_yaml = data.to_yaml

  private

  def association_attributes(association) = association_model(association).ransackable_attributes(authorizable)

  def association_headers(association)
    association_attributes(association).map { |attribute| "#{association_model(association).human_attribute_name(attribute)} (#{association.to_s.humanize})" }
  end

  def association_model(association) = @record_class.reflect_on_association(association).klass

  def association_values(record, association)
    association_attributes(association).map { |attribute| format_value(record.public_send(association)&.authorized_attribute!(attribute, authorizable), attribute) }
  end

  def attribute_headers = attributes.map { |attribute| @record_class.human_attribute_name(attribute) }
  def attribute_values(record) = attributes.map { |attribute| format_value(record.authorized_attribute!(attribute, authorizable), attribute) }
  def attributes = @attributes ||= @record_class.ransackable_attributes(authorizable)

  def exportable_associations
    @exportable_associations ||= @record_class
                                 .ransackable_associations(authorizable)
                                 .map(&:to_sym)
                                 .select { |association| association_model(association).try(:authorized_attributable?) }
  end

  def format_phone(value) = "+1#{value.to_s.gsub(/\D/, '').last(10)}"
  def format_value(value, attribute = nil) = attribute.to_s.include?('phone') ? format_phone(value) : (value.try(:format).presence || value)
  def headers = attribute_headers + exportable_associations.flat_map { |association| association_headers(association) }
  def row_for(record) = attribute_values(record) + exportable_associations.flat_map { |association| association_values(record, association) }
end
