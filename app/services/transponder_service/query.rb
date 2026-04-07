module TransponderService
  module Query
    class << self
      attr_reader :broker_carrier, :input_class

      def call(query_name, broker_carrier, object, **kwargs)
        @broker_carrier = broker_carrier

        @input_class = "TransponderService::Input::#{query_name.to_s.camelize}".constantize

        query = base_query
        query.merge!(input_class.call(object, **kwargs))

        query
      end

      private

      def base_query
        { carrier: Input.call(broker_carrier) }
      end
    end
  end
end
