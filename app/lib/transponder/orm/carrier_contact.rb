module Transponder
  module ORM
    class CarrierContact < Base
      class << self
        def all = Collection.new(self, Carrier.all.flat_map(&:contacts))
        def primary_key = :id
      end

      attr_reader :company_name, :department, :email, :fax, :id, :name, :phone

      def initialize( # rubocop:disable Metrics/ParameterLists
        id:,
        company_name: nil,
        department: nil,
        email: nil,
        fax: nil,
        name: nil,
        phone: nil
      )
        super()

        @company_name = company_name
        @department = department
        @email = email
        @fax = fax
        @id = id
        @name = name
        @phone = phone
      end
    end
  end
end
