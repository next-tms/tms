# frozen_string_literal: true

module ProblematicService
  class Rule::Base
    attr_reader :processor, :record

    def initialize(processor)
      @processor = processor
    end

    def call(record)
      with(record)

      problems = record.problems.where(problematic_rule_code: code, resolvable: record)

      if resolvable?
        problems.unresolved.update_all(resolved_at: Time.current, resolved_by_id: record.updated_by&.id)

        return record.problems
      end

      roles.find_each do |role|
        role_problems = problems.where(assigned_to: role.users.where(broker: record.broker).broker)

        if role_problems.any?
          role_problems.update_all(resolved_at: nil, resolved_by_id: nil)
          next
        end

        Problem.create!(
          assigned_to: assign(role),
          problematic_rule_code: code,
          resolvable: record,
          title: humanized(:title)
        )
      end

      record.reload.problems
    end

    def code
      @code ||= self.class.name.demodulize.snakecase
    end

    def problematic?
      raise NotImplementedError
    end

    def resolvable?
      raise NotImplementedError
    end

    def roles
      raise NotImplementedError
    end

    def suppressor_instigators
      []
    end

    def suppressor_suppressible_types
      []
    end

    def suppressors
      return Suppressor.none if suppressor_instigators.empty? || suppressor_suppressible_types.empty?

      Suppressor.where(
        instigator: suppressor_instigators,
        problematic_rule_code: code,
        suppressible_type: suppressor_suppressible_types
      )
    end

    def with(record)
      @record = record

      self
    end

    private

    def assign(role)
      return record.dispatcher if role.name == 'dispatch' &&
                                  record.is_a?(Shipment) &&
                                  record.dispatcher.present?

      users = role.users.where(broker: record.broker).broker

      # User with least amount of problems
      assigned_to = users
                    .left_outer_joins(:problems)
                    .active
                    .group('users.id')
                    .order('count(problems.assigned_to_id) ASC')
                    .limit(1)
                    .first

      return assigned_to unless assigned_to.blank?

      Rails.logger.warn <<~WARN.squish
        Unable to find User with broker=(name: "#{record.broker.name}"),
                                 role=(name: [#{roles.pluck(:name).join(', ')}])
      WARN

      Role
        .find_by_name('root')
        .users
        .active
        .where(broker:)
        .broker
        .order(Arel.sql('RANDOM()'))
        .limit(1)
        .first
    end
  end
end
