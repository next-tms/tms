# frozen_string_literal: true

module ProblematicService
  class Processor::Base
    class << self
      def call(record)
        Problem.where(id: rules.map { |rule| rule.call(record).ids }.flatten)
      end

      def model
        raise NotImplementedError
      end

      def rules
        Dir[Rails.root.join('app', 'services', 'problematic_service', 'rule', model.name.snakecase, '*.rb')].map do |fn|
          ['ProblematicService', 'Rule', model.name, File.basename(fn)[..-4].camelcase]
          .join('::')
          .constantize
          .new(self)
        end
      end
    end
  end
end
