module Transponder
  module ORM
    class Terminal < Base
      class << self
        def all = Collection.new(self, Carrier.all.flat_map(&:terminals))
        def primary_key = :id
      end

      attr_reader :address, :carrier, :id, :phone

      def initialize(id:, address: nil, carrier: nil, phone: nil)
        super()

        @address = CarrierAddress.new(**address) if address.present?
        @carrier = carrier
        @id = id
        @phone = phone
      end
    end
  end
end
