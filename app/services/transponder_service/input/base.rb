module TransponderService
  module Input
    class Base
      class << self
        def call(object, **)
          new(object, **).call
        end
      end

      attr_reader :object, :options

      def initialize(object, **_kwargs)
        @object = object
      end

      def build
        raise NotImplementedError
      end

      def call
        result = build
        return if result.blank?

        build.compact.deep_transform_keys { |key| key.to_s.camelize(:lower) }
      end
    end
  end
end
