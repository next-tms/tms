# frozen_string_literal: true

class Shipment::LinearFtService
  # @return [Measured::Length]
  class << self
    def call(shipment, trailer_length: DEFAULT_TRAILER_LENGTH)
      new(shipment).call(trailer_length)
    end
  end

  class UncalculableError < StandardError; end

  DEFAULT_TRAILER_LENGTH = Measured::Length.new(48, :ft)

  attr_reader :shipment

  delegate :flattened_items, to: :shipment

  def initialize(shipment)
    raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(::Shipment)

    @shipment = shipment
  end

  # @return [Measured::Length]
  def call(trailer_length)
    raise ArgumentError, 'trailer_length must be a Measured::Length' unless trailer_length.is_a?(Measured::Length)

    if flattened_items.any? { |item| [item.l, item.w, item.h].any?(&:blank?) }
      raise UncalculableError, 'All items must have specified dimensions'

    end

    trailer_length_ft = trailer_length.convert_to(:ft).value.floor

    value = flattened_items.sum { |item| (item.cubic_ft(rounded: false).to_f / trailer_length_ft).ceil }
    Measured::Length.new(value, :ft)
  end
end
