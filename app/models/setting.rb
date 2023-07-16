# frozen_string_literal: true

# == Schema Information
#
# Table name: settings
#
# @!attribute id
#   @return []
# @!attribute key
#   @return [String]
# @!attribute value
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_settings_on_key  (key)
#
class Setting < ApplicationRecord
  class << self
    def first_value(*keys)
      keys.map { |key| value(key) }.find(&:present?)
    end

    def required_keys
      CONFIGURATION.select { |entry| !!entry[:required] }.map { |entry| entry[:key] }
    end

    def keys
      CONFIGURATION.map { |entry| entry[:key] }
    end

    def value(key, fallback_value = nil)
      value!(key).presence || fallback_value
    rescue ActiveRecord::RecordNotFound
      fallback_value
    end

    def value!(key)
      find_by!(key: key.to_s).value
    end
  end

  BOOLEAN_VALUES = { false: 'boolean:false', true: 'boolean:true' }.freeze
  CONFIGURATION = Psych.load_file(Rails.root.join('config/settings.yml'), symbolize_names: true).freeze
  DOMAIN_REGEX = /\b((xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\b/

  audited

  phony_normalize :phone_number, default_country_code: 'US', if: -> { kind == :phone }

  validate :validate_value

  validates :key, uniqueness: true

  validates_plausible_phone :phone_number, presence: true, if: -> { kind == :phone }

  def help
    return if key.blank?

    I18n.t("settings.#{key}", raise: true)
  rescue I18n::MissingTranslationData
    nil
  end

  def kind
    return if key.blank?

    entry = CONFIGURATION.find { |entry| entry[:key] == key }
    return if entry.blank?

    entry[:kind]
  end

  def value
    return super unless BOOLEAN_VALUES.values.include?(super)

    BOOLEAN_VALUES[:true] == super
  end

  def value=(new_value)
    return super unless [true, false, 'true', 'false'].include?(new_value)

    if new_value.is_a?(String)
      return self.value = new_value == 'true' ? BOOLEAN_VALUES[:true] : BOOLEAN_VALUES[:false]
    end

    self.value = new_value == true ? BOOLEAN_VALUES[:true] : BOOLEAN_VALUES[:false]
  end

  private

  def validate_value
    return if kind.blank?

    case kind
    when :boolean
      return if value.is_a?(TrueClass) || value.is_a?(FalseClass)

      errors.add(:value, 'must be true or false')
    when :email
      return if value =~ URI::MailTo::EMAIL_REGEXP

      errors.add(:value, 'must be an email address')
    when :hostname
      return if value =~ DOMAIN_REGEX

      errors.add(:value, 'must be a domain')
    when :integer
      return if value.to_i.to_s == value && value.to_i.positive?

      errors.add(:value, 'must be a positive integer')
    when :time_zone
      time_zone_names = ActiveSupport::TimeZone.all.map(&:tzinfo).map(&:name)
      return if time_zone_names.include?(value)

      errors.add(:value, 'must be a time zone')
    when :uri
      begin
        uri = URI.parse(value)
      rescue URI::InvalidURIError
        return errors.add(:value, 'must be a URI')
      end

      return if [uri.scheme, uri.host].all?(&:present?)

      errors.add(:value, 'must be a URI')
    end
  end
end
