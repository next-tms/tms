class Setting < ApplicationRecord
  class << self
    def first_value(*keys)
      keys.map { |key| value(key) }.find(&:present?)
    end

    def configuration = @configuration ||= Psych.load_file(Rails.root.join('config/settings.yml'), symbolize_names: true).freeze
    def keys = configuration.pluck(:key)
    def required_keys = configuration.select { |entry| entry[:required] }.pluck(:key)

    def method_missing(method_name, *)
      key = method_name.to_s.delete_suffix('!')
      return super unless keys.include?(key)

      method_name.end_with?('!') ? value!(key, *) : value(key, *)
    end

    def respond_to_missing?(method_name, include_private = false) = keys.include?(method_name.to_s.delete_suffix('!')) || super

    def value(key, fallback_value = nil)
      value!(key)
    rescue ActiveRecord::RecordNotFound
      fallback_value
    end

    def value!(key)
      find_by!(key: key.to_s).value
    end

    def time_zone = ActiveSupport::TimeZone.new(value!(:time_zone_name))
  end

  include ::Instigatable
  include Setting::Instigatable

  BOOLEAN_VALUES = { false: 'boolean:false', true: 'boolean:true' }.freeze
  DOMAIN_REGEX = /\b((xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\b/

  after_save :update_broker_carriers_ignore_bol_requires_tracking_number, if: -> {
    key == 'ignore_broker_carrier_bol_requires_tracking_number'
  }

  before_save :save_address, if: :address?

  audited

  phony_normalize :value, default_country_code: 'US', if: :phone?

  validate :validate_value

  validates :key, uniqueness: true

  validates_plausible_phone :value, presence: true, if: :phone?

  def address
    return unless address?
    return @address if @address && (@address.new_record? || @address.id.to_s == self[:value])

    @address = Address.find_by(id: self[:value]) || Address.new
  end

  def address? = kind == :address

  def address_attributes=(attributes)
    return unless address?

    address.assign_attributes(attributes)
  end

  def help
    return if key.blank?

    I18n.t("settings.#{key}", raise: true)
  rescue I18n::MissingTranslationData
    nil
  end

  def kind
    return if key.blank?

    entry = self.class.configuration.find { |entry| entry[:key] == key }
    return if entry.blank?

    entry[:kind]
  end

  def phone? = kind == :phone

  def value
    return address if address?
    return super unless BOOLEAN_VALUES.values.include?(super)

    BOOLEAN_VALUES[:true] == super
  end

  def value=(new_value)
    if new_value.is_a?(Address)
      @address = new_value
      super(new_value.id&.to_s)
    elsif [true, false, 'true', 'false'].include?(new_value)
      super([true, 'true'].include?(new_value) ? BOOLEAN_VALUES[:true] : BOOLEAN_VALUES[:false])
    else
      super
    end
  end

  private

  def save_address
    return unless address.changed?

    self.value = address.tap(&:save!)
  end

  def update_broker_carriers_ignore_bol_requires_tracking_number
    return unless saved_change_to_value?

    BrokerCarrier.update_all(ignore_bol_requires_tracking_number: value) # rubocop:disable Rails/SkipsModelValidations
  end

  def validate_value
    return if kind.blank?

    case kind
    when :address
      if address.changed?
        address.validate
        address.errors.each { |error| errors.add(:address, error.full_message) }
      elsif address.new_record?
        errors.add(:address, 'must be present')
      end
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
