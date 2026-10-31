module ProblematicService
  class Rule
    class << self
      def all
        # Preferably we'd just use:
        #
        # descendants
        #
        # but doing it this way avoids a lot of work with eager loading in development:

        Dir.glob(File.join(__dir__, 'rule', '*', '*.rb')).map { |path| path.split('/').last(2) }.map do |parts|
          model_name = parts[0].camelcase
          rule_name = File.basename(parts[1], '.rb').camelcase
          "ProblematicService::Rule::#{model_name}::#{rule_name}".constantize
        end
      end

      def by_any_role(*roles)
        raise ArgumentError, 'roles must all be Symbol' unless roles.all? { |role| role.is_a?(Symbol) }

        contact_roles = ContactRole.roles.keys.map(&:to_sym)
        roles.each do |role|
          next if contact_roles.include?(role)

          raise ArgumentError, "Role must be one of #{contact_roles.keys.join(", ")}"
        end

        all.select { |rule| rule.roles.intersect?(roles) }
      end

      def code = name.demodulize.underscore
      def humanized = raise NotImplementedError
      def model = ancestors[1].name.demodulize.constantize
      def roles = self::ROLES
    end

    attr_reader :processor, :record

    def initialize(processor)
      @processor = processor
    end

    def call(record)
      with(record)

      problems = record.problems.where(problematic_rule_code: code)

      if resolvable?
        problems.unresolved.find_each { |problem| problem.update!(resolved_at: Time.current, resolved_by: record.updated_by) }
      elsif problems.any?
        problems.resolved.find_each { |problem| problem.update!(resolved_at: nil, resolved_by: nil) }
      else
        Problem
        .create!(
          assigned_to: assign,
          problematic_rule_code: code,
          resolvable: record,
          title: humanized(:title),
        )
      end
    end

    # @todo Deprecate
    def code = self.class.code

    # @todo Deprecate
    def humanized = self.class.humanized

    def problematic? = raise NotImplementedError
    def resolvable? = raise NotImplementedError

    # @todo Deprecate
    def roles = self.class.roles

    def suppressor_instigators = []
    def suppressor_suppressible_types = []

    def suppressors
      return Suppressor.none if suppressor_instigators.empty? || suppressor_suppressible_types.empty?

      Suppressor
      .where(
        instigator: suppressor_instigators,
        problematic_rule_code: code,
        suppressible_type: suppressor_suppressible_types,
      )
    end

    def with(record)
      @record = record

      self
    end

    private

    def assign
      return record.dispatcher if record.is_a?(::Shipment) &&
                                  record.dispatcher.present? &&
                                  roles.any?(:dispatch)

      users = User.broker.with_any_role(*roles)

      # User with least amount of problems
      assigned_to = users
                    .left_outer_joins(:problems)
                    .active
                    .group('users.id')
                    .order('count(problems.assigned_to_id) ASC')
                    .limit(1)
                    .first

      return assigned_to if assigned_to.present?

      Rails.logger.warn(<<~WARN.squish)
        Unable to find User with broker=(name: "#{Setting.value(:name)}"), role=(name: [#{roles.join(", ")}])
      WARN

      Role.find_by(name: 'root').users.active.broker.order(Arel.sql('RANDOM()')).limit(1).first
    end
  end
end
