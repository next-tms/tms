module AccountingSyncable
  extend ActiveSupport::Concern

  class_methods do
    def accounting_syncs(resource, match:, columns: nil, prepare: nil)
      builder = :"to_accounting_#{resource}"
      id_column = :"accounting_#{resource}_id"

      define_method(:"accounting_#{resource}") do
        return unless Accounting.connected? && Accounting.supports?(resource)

        memo = (@accounting_records ||= {})
        return memo[resource] if memo[resource].present?

        klass = Accounting.record_class(resource)
        found = klass.find(public_send(id_column)) if public_send(id_column).present?
        return memo[resource] = found if found.present?

        found = klass.find_by(**instance_exec(&match))
        return if found.blank?

        memo[resource] = found
        self[id_column] = found.id
        save! if persisted?
        found
      end

      define_method(:"create_accounting_#{resource}") do
        return unless Accounting.connected? && Accounting.supports?(resource)
        return public_send(:"update_accounting_#{resource}") if public_send(:"accounting_#{resource}").present?

        memo = (@accounting_records ||= {})
        payload = public_send(builder)
        instance_exec(payload, &prepare) if prepare
        result = Accounting.record_class(resource).create(payload.attributes)
        return memo[resource] = nil if result.blank?

        update!(id_column => result.id, **columns ? instance_exec(&columns) : {})
        memo[resource] = result
      end

      define_method(:"update_accounting_#{resource}") do
        return unless Accounting.connected? && Accounting.supports?(resource)
        return public_send(:"create_accounting_#{resource}") if public_send(:"accounting_#{resource}").blank?

        memo = (@accounting_records ||= {})
        payload = public_send(builder)
        instance_exec(payload, &prepare) if prepare
        memo[resource] = Accounting.record_class(resource).new(public_send(id_column), **payload.attributes).save
      end
    end
  end
end
