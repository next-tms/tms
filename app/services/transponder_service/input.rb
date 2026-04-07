# frozen_string_literal: true

module TransponderService
  module Input
    class << self
      def call(object, **kwargs)
        input = input(object)

        if input.blank?
          classes = MAPPING.values.keys.map { |key| key.to_s.camelize }
          raise ArgumentError, "object must be one of: #{classes.join(", ")}"
        end

        input.call(object, **kwargs)
      end

      def input(object)
        class_name = MAPPING[object.class.to_s.demodulize.snakecase.to_sym].to_s.camelize

        [ 'TransponderService', 'Input', class_name ].join('::').constantize
      end
    end

    MAPPING = {
      address: :location,
      broker_carrier: :carrier,
      contact: :contact,
      item: :package,
      overlength_rule: :overlength_rule,
      packaging: :packaging,
      shipment: :shipment,
      time: :date_time
    }
  end
end
