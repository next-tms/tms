module Transponder
  module ORM
    class Lane < Base
      class << self
        def all = Collection.new(self, Carrier.all.flat_map(&:lanes))
        def primary_key = :id
      end

      attr_reader :carrier, :destination, :id, :origin

      def initialize(id:, carrier: nil, destination: nil, origin: nil)
        super()

        @carrier = carrier
        @destination = Territory.new(**destination) if destination.present?
        @id = id
        @origin = Territory.new(**origin) if origin.present?
      end

      def name = "#{origin} → #{destination}"
    end
  end
end
