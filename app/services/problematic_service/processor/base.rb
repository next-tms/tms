module ProblematicService
  class Processor::Base
    class << self
      def call(record) = rules.each { |rule| rule.call(record) }
      def model = raise NotImplementedError

      def rules
        Rails.root.glob("app/services/problematic_service/rule/#{model.name.underscore}/*.rb").map do |fn|
          [ 'ProblematicService', 'Rule', model.name, File.basename(fn)[..-4].camelcase ]
          .join('::')
          .constantize
          .new(self)
        end
      end
    end
  end
end
