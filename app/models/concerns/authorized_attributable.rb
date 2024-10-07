module AuthorizedAttributable
  class UnauthorizedAttributeError < StandardError; end

  extend ActiveSupport::Concern

  class_methods do
    def authorized_attributable? = true
    def policy_class = "#{name}Policy".constantize

    def ransackable_attributes(authorizable = nil)
      return [] if authorizable.blank?

      return ransackable_broker_attributes if authorizable.broker?
      return ransackable_customer_attributes if authorizable.customer?

      []
    end

    private

    def ransackable_broker_attributes = ransackable_customer_attributes + policy_class::BROKER_ATTRIBUTES.map(&:to_s)
    def ransackable_customer_attributes = policy_class::CUSTOMER_ATTRIBUTES.map(&:to_s)
  end

  def authorized_attribute!(attribute, authorizable)
    return public_send(attribute) if authorized_attribute?(attribute, authorizable)

    raise UnauthorizedAttributeError, "Unauthorized access to ##{attribute}"
  end

  def authorized_attribute?(attribute, authorizable) = policy(authorizable).public_send("#{attribute}_attribute?")
  def authorized_attributable? = true
  def authorized_attributes?(*attributes, authorizable) = attributes.all? { |attribute| authorized_attribute?(attribute, authorizable) }
  def policy(authorizable) = self.class.policy_class.new(self, authorizable:)
end
