module TransponderService
  module Input
    class Package < Base
      def initialize(object, declared_freight_classes:)
        raise ArgumentError, 'declared_freight_classes must be one of: true, false' if [true, false].exclude?(declared_freight_classes)

        @declared_freight_classes = declared_freight_classes

        super
      end

      def build
        {
          description: object.desc.presence,
          dimensions:,
          freight_class:,
          hazardous: object.hazmat?,
          nmfc: object.nmfc&.to_s,
          packaging:,
          weight:
        }
      end

      private

      def declared_freight_classes?
        @declared_freight_classes
      end

      def dimensions
        Dimensions.call(object)
      end

      def freight_class
        value = if declared_freight_classes?
                  object.declared_freight_class.presence || object.calculated_freight_class
                else
                  object.calculated_freight_class.presence || object.declared_freight_class
                end
        return if value.blank?

        "_#{value.to_s.gsub('.', '_')}" # e.g. 77.5 → _77_5
      end

      def packaging
        object.packaging.freight_kit_type
      end

      def weight
        Weight.call(object)
      end
    end
  end
end
