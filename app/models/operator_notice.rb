class OperatorNotice
  include ActiveModel::API
  include ActiveModel::Attributes

  attribute :action_url, :string
  attribute :enforce_at, :datetime
  attribute :message, :string
  attribute :status, :string

  class << self
    def current = OFREP.configured? ? new(Rails.cache.read(CACHE_KEY).to_h.slice(*attribute_names)) : new

    def refresh!
      value = OFREP.evaluate(FLAG_KEY)
      value.is_a?(Hash) ? Rails.cache.write(CACHE_KEY, value) : Rails.cache.delete(CACHE_KEY)
    end
  end

  CACHE_KEY = 'operator_notice'.freeze
  FLAG_KEY = 'operator_notice'.freeze

  def cache_key = "operator_notice/#{Digest::SHA256.hexdigest(attributes.to_json)}"
  def enforced? = suspended? || (past_due? && enforce_at.present? && enforce_at.past?)
  def link_url = (action_url if action_url.to_s.match?(%r{\Ahttps?://}i))
  def past_due? = status == 'past_due'
  def suspended? = status == 'suspended'
  def visible_to?(user) = past_due? && !enforced? && message.present? && user&.broker? && user.any_role?(:accounting)
end
