module Transponder
  module ORM
    class Accessorial < ::ORM::Base
      class << self
        def all = @all ||= ::ORM::Collection.new(self, codes.map { |code| new(code:) })
        def primary_key = :code

        private

        def codes = GraphQLClient::Transponder::Schema.get_type(ENUM_TYPE).values.keys.map(&:downcase)
      end

      ENUM_TYPE = 'AccessorialCategory'.freeze

      attr_reader :code

      def initialize(code:)
        super()

        @code = code
      end

      def cache_version = code
      def name = code.titleize
    end
  end
end
