class Report < ApplicationRecord
  def self.blank_filter?(value) = value != false && value.blank?

  include Report::Runnable

  belongs_to :created_by, class_name: 'User'

  normalizes :columns, apply_to_nil: true, with: ->(columns) { Array(columns).compact_blank.map(&:to_s) }
  normalizes :date_attribute, with: ->(date_attribute) { date_attribute.presence }
  normalizes :filters, apply_to_nil: true, with: lambda { |filters|
    filters
      .to_h
      .stringify_keys
      .transform_values { |value| value.is_a?(Array) ? value.reject { |item| blank_filter?(item) } : value }
      .reject { |_key, value| blank_filter?(value) }
  }

  validates :columns, presence: true
  validates :name, presence: true, uniqueness: true
  validates :record_type, inclusion: { in: RECORD_TYPES }
  validate :validate_columns
  validate :validate_date_attribute
  validate :validate_filters
  validate :validate_record_type

  def headers = {}
  def preset? = false

  def remember_date_range(from, to, today) = update(from_days_ago: (today - from).to_i, to_days_ago: (today - to).to_i)

  private

  def validate_columns
    return if created_by.blank? || record_class.blank?

    available = columns.all? { |column| ExporterService.column_available?(record_class, column, created_by) }
    errors.add(:columns, :inclusion) unless available
  end

  def validate_date_attribute
    return if date_attribute.blank? || created_by.blank? || record_class.blank?

    errors.add(:date_attribute, :inclusion) unless date_attributes(created_by).include?(date_attribute)
  end

  def validate_filters
    return if created_by.blank? || record_class.blank?

    record_class.ransack(filters, auth_object: created_by)
  rescue ArgumentError
    errors.add(:filters, :invalid)
  end

  def validate_record_type
    return if created_by.blank? || record_class.blank?

    errors.add(:record_type, :inclusion) unless Report::Runnable.record_type_available?(record_type, created_by)
  end
end
