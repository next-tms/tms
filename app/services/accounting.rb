module Accounting
  class Error < StandardError; end
  class UnsupportedResource < Error; end

  class << self
    def connected? = integration.present?
    def integration = Integration.where(kind: KINDS).find(&:connected?)

    def money(value)
      case value
      when BigDecimal then Money.from_amount(value)
      when Integer then Money.new(value)
      when NilClass then nil
      else
        raise ArgumentError, "Not sure how to parse #{value.class}"
      end
    end

    def record_class(resource)
      integration.service.class.module_parent.const_get(resource.to_s.camelize, false)
    rescue NameError
      raise UnsupportedResource, resource.to_s
    end

    def supports?(resource)
      record_class(resource)
      true
    rescue UnsupportedResource
      false
    end
  end

  KINDS = %i[quickbooks wave].freeze
  RESOURCES = %i[account bill bill_payment customer invoice vendor].freeze
end
