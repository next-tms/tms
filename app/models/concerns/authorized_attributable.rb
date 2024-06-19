# frozen_string_literal: true

module AuthorizedAttributable
  class UnauthorizedAttributeError < StandardError; end

  extend ActiveSupport::Concern

  class_methods do
    def ransackable_attributes(authorizable)
      "#{policy_class}::#{authorizable.type.upcase}_ATTRIBUTES".constantize
    end

    def policy_class
      "#{name}Policy".constantize
    end
  end

  def authorized_attribute!(attribute, authorizable)
    return public_send(attribute) if authorized_attribute?(attribute, authorizable)

    raise UnauthorizedAttributeError, "Unauthorized access to ##{attribute}"
  end

  def authorized_attribute?(attribute, authorizable)
    policy(authorizable).public_send("#{attribute}_attribute?")
  end

  private

  def policy(authorizable)
    self.class.policy_class.new(self, authorizable:)
  end
end
