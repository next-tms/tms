module TransponderService
  module Query
    class << self
      def call(query_name, broker_carrier, object, **)
        input_class = "TransponderService::Input::#{query_name.to_s.camelize}".constantize

        query = base_query(broker_carrier)
        query.merge!(input_class.call(object, **))

        query
      end

      private

      def base_query(broker_carrier) = { carrier: Input.call(broker_carrier) }
    end
  end
end
