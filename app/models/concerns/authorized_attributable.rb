module AuthorizedAttributable
  class UnauthorizedAttributeError < StandardError; end

  extend ActiveSupport::Concern

  class_methods do
    def authorized_attributable? = true
    def policy_class = "#{name}Policy".constantize
    def ransackable_attributes(authorizable) = "#{policy_class}::#{authorizable.type.upcase}_ATTRIBUTES".constantize
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
