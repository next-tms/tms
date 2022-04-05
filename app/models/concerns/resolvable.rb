# frozen_string_literal: true

module Resolvable
  extend ActiveSupport::Concern

  included do
    after_save :resolve_problems

    def resolve_problems
      return unless methods.include?(:broker)

      problem_types = ProblemType.where(resolvable_class_name: self.class.name)

      return if problem_types.blank?

      problem_types.find_each do |problem_type|
        attribute = problem_type.resolvable_class_attribute_name.to_sym
        next unless saved_change_to_attribute?(attribute)

        problems = Problem.where(assigned_to: broker.users.broker).unresolved.where(problem_type:)
        next if problems.blank?

        problems.find_each do |problem|
          resolved = false

          case problem_type.resolves_when_class_attribute_is
          when 'attached'
            resolved = true if send(attribute).attached?
          when 'blank'
            resolved = true if send(attribute).blank?
          when 'blank_false'
            resolved = true unless send(attribute).blank?
          end

          next unless resolved

          resolved_by_id = methods.include?(:updated_by_id) ? send(:updated_by_id) : nil
          problem.update(resolved_at: DateTime.current, resolved_by_id:)
        end
      end
    end
  end
end
