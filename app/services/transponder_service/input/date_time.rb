# frozen_string_literal: true

module TransponderService
  module Input
    class DateTime < Base
      def build
        {
          iso8601: object.iso8601
        }
      end
    end
  end
end
