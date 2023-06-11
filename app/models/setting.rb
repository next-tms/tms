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

  validates :key, :value, presence: true
  validates :key, uniqueness: true

  def value
    return super unless BOOLEAN_VALUES.values.include?(super)

    BOOLEAN_VALUES[:true] == super
  end

  def value=(new_value)
    return super unless [true, false].include?(new_value)

    self.value = new_value == true ? BOOLEAN_VALUES[:true] : BOOLEAN_VALUES[:false]
  end
end
