module Ransackable
  extend ActiveSupport::Concern

  class_methods do
    def broker_authorizable?(auth_object) = auth_object.is_a?(User) && auth_object.broker?
    def broker_only_column?(column_name) = column_name.match?(BROKER_ONLY_COLUMN_PATTERN)
    def json_column?(column_name) = columns_hash[column_name]&.type.in?(%i[json jsonb])
    def pricing_column?(column_name) = column_name.match?(PRICING_COLUMN_PATTERN)

    def private_associations(auth_object)
      companyable = auth_object.try(:companyable)
      return ['broker_customer'] if companyable.is_a?(Carrier)
      return ['broker_carrier'] if companyable.is_a?(BrokerCustomer)

      []
    end

    def ransack_aliases(_auth_object = nil) = {}

    def ransackable_associations(auth_object = nil)
      return [] unless broker_authorizable?(auth_object)

      reflect_on_all_associations.reject(&:collection?).map { |reflection| reflection.name.to_s }
    end

    def ransackable_attributes(auth_object = nil) = (ransackable_columns(auth_object) | _ransackers.keys).sort

    def ransackable_columns(auth_object)
      column_names.reject do |column_name|
        next true if secret_column?(column_name) || json_column?(column_name)

        !broker_authorizable?(auth_object) && (broker_only_column?(column_name) || pricing_column?(column_name))
      end
    end

    def secret_column?(column_name) = column_name.match?(SECRET_COLUMN_PATTERN) || encrypted_attributes.to_a.include?(column_name.to_sym)
  end

  BROKER_ONLY_COLUMN_PATTERN = /\A(accounting_notes|broker_and_broker_customer_notes|broker_notes|internal_notes)\z/
  PRICING_COLUMN_PATTERN = /_cents\z|_currency\z|commission|cost|padding|upcharge/
  SECRET_COLUMN_PATTERN = /digest|encrypted|_ip\z|otp|password|salt|secret|token|username/
end
