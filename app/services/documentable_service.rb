# frozen_string_literal: true

module DocumentableService
  class << self
    def call(record)
      record.class::DOCUMENTABLE_TYPES.each do |documentable_type|
        "DocumentableService::#{record.class}::#{documentable_type.to_s.camelcase}".constantize.call(record)
      end
    end
  end
end
