# frozen_string_literal: true

module DocumentableService
  class << self
    def call!(record, document_type)
      "DocumentableService::#{record.class}".constantize.call!(record, document_type)
    end
  end
end
