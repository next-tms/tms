module Normalizable
  extend ActiveSupport::Concern

  included do
    self::DOWNCASEABLE_ATTRIBUTES.each { |attribute| normalizes attribute, with: ->(value) { value.downcase } }
    self::SQUISHABLE_ATTRIBUTES.each { |attribute| normalizes attribute, with: ->(value) { value.squish } }
  end
end
