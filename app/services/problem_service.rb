# frozen_string_literal: true

class ProblemService
  def self.assign(broker, problem_type)
    users = problem_type.role.users.where(broker:).broker

    # User with least amount of problems
    assigned_to = users
                  .left_outer_joins(:problems)
                  .active
                  .group('users.id')
                  .order('count(problems.assigned_to_id) ASC')
                  .limit(1)
                  &.first

    return assigned_to unless assigned_to.blank?

    Role
      .find_by_name('root')
      .users
      .active
      .where(broker:)
      .broker
      .order(Arel.sql('RANDOM()'))
    &.last
  end

  def self.create_problems
    ProblemType.all.find_each do |problem_type|
      next if problem_type.resolvable_class_name.blank?

      model = problem_type.resolvable_class_name.constantize
      attribute = problem_type.resolvable_class_attribute_name.to_sym
      since_attribute = problem_type.resolvable_class_since_attribute_name.to_sym

      verb = problem_type.resolves_when_class_attribute_is
      verb = verb.end_with?('false') ? verb.sub('_false', '') : "not_#{verb}"

      scope = "problematic_#{attribute}_#{verb}".to_sym

      model.send(scope).where("#{since_attribute} >= ?", 1.month.ago).find_each do |resolvable|
        resolved_problems = resolvable.problems.where(problem_type:)

        if resolved_problems.any?
          resolved_problems.update_all(resolved_at: nil, resolved_by_id: nil)
          next
        end

        assigned_to = if resolvable.is_a?(Shipment) && resolvable.dispatcher.present?
                        shipment.dispatcher
                      else
                        assign(resolvable.broker, problem_type)
                      end

        Problem.create(assigned_to:, problem_type:, resolvable:, title: problem_type.name.titleize)
      end
    end
  end

  def self.resolve_problems
    problems = Problem
               .unresolved
               .where(resolvable_type: 'Shipment')
               .where(resolvable_id: Receivable.paid.pluck(:shipment_id))
    problems.update_all(
      resolved_at: DateTime.current,
      resolved_by_id: nil
    )
  end
end
