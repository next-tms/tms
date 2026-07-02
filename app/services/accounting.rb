module Accounting
  class << self
    def connected? = integration.present?
    def integration = Integration.where(kind: KINDS).find(&:connected?)
    def record_class(resource) = integration.service.class.module_parent.const_get(resource.to_s.camelize)
  end

  Error = Class.new(StandardError)
  UnsupportedResource = Class.new(Error)

  KINDS = %i[quickbooks wave].freeze
  RESOURCES = %i[account bill bill_payment customer invoice vendor].freeze
end
