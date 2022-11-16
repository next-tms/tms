# frozen_string_literal: true

module ProblematicService
  class Processor::Receivable < Processor::Base
    class << self
      def model
        Receivable
      end
    end
  end
end
