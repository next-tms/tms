# frozen_string_literal: true

class CreateReceivableProblemJob < ApplicationJob
  def perform(receivable)
    return unless receivable.missing_carrier_bol? || receivable.missing_carrier_pod?

    next unless receivable.missing_carrier_bol? || receivable.missing_carrier_pod?
    next if receivable.missing_carrier_bol? && !receivable.shipment.picked_up?
    next if receivable.missing_carrier_pod? && !receivable.shipment.delivered?

    problem_codes = []
    problem_codes << 'receivable_missing_carrier_bol' if receivable.missing_carrier_bol?
    problem_codes << 'receivable_missing_carrier_pod' if receivable.missing_carrier_pod?

    # Assign the same person to all problems
    assigned_to = Role
                  .find_by_name('accounts_receivable')
                  .users
                  .broker
                  .where(broker: receivable.broker)
                  .order(Arel.sql('RANDOM()'))
                  &.last

    if assigned_to.blank?
      assigned_to = Role
                    .find_by_name('root')
                    .users
                    .broker
                    .where(broker: receivable.broker)
                    .order(Arel.sql('RANDOM()'))
                    &.last
    end

    problem_codes.each do |problem_code|
      problem_type = ProblemType.find_by_code(problem_code)
      shipment = receivable.shipment

      next if Problem.where(problem_type:, shipment:).any?

      title = "Receivable #{receivable.shipment.load_id} is #{problem_type.name}"
      body = "Receivable #{receivable.shipment.load_id} is #{problem_type.name}"

      Problem.create(assigned_to:, body:, problem_type:, shipment:, title:)
    end
  end
end
