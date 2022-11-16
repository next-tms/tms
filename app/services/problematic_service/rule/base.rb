# frozen_string_literal: true

module ProblematicService
  class Rule::Base
    attr_reader :processor, :record

    def initialize(processor)
      @processor = processor
    end

    def call(record)
      @record = record

      problems = record.problems.where(problematic_rule_code: code)

      if resolvable?
        problems.unresolved.update_all(
          resolved_at: Time.current,
          resolved_by_id: record.updated_by.id
        )

        return record.problems unless problematic?
      end

      roles.find_each do |role|
        problems = problems.where(assigned_to: role.users.where(broker: record.broker).broker)

        if problems.any?
          problems.update_all(resolved_at: nil, resolved_by_id: nil)
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

    private

    def assign(role)
      users = role.users.where(broker: record.broker).broker

      return record.dispatcher if role.name == 'dispatch' &&
                                  record.is_a?(Shipment) &&
                                  record.dispatcher.present?

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
        Unable to find User with broker=(name: \"#{record.broker.name}\"),
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
