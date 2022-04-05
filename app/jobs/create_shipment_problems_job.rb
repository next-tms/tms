# frozen_string_literal: true

class CreateShipmentProblemsJob < ApplicationJob
  def perform
    Broker.all.find_each do |broker|
      today = DateTime.current.in_time_zone(broker.time_zone).to_date

      from = today - 7.days
      to = today - 1.day

      Shipment.pending_pickup.where(pickup_on: (from..to)).find_each do |shipment|
        assigned_to = Role
                      .find_by_name('dispatch')
                      .users
                      .broker
                      .where(broker:)
                      .order(Arel.sql('RANDOM()'))
                      &.last

        if assigned_to.blank?
          assigned_to = Role
                        .find_by_name('root')
                        .users
                        .broker
                        .where(broker:)
                        .order(Arel.sql('RANDOM()'))
                        &.last
        end

        problem_type = ProblemType.find_by_code('not_picked_up')

        next if shipment.problems.unresolved.where(problem_type:).any?

        title = "Load #{shipment.load_id} is #{problem_type.name}"
        body = "Load #{shipment.load_id} was scheduled for pickup on #{ApplicationController.helpers.short_date(
          shipment.pickup_on, broker.time_zone
        )} but was not marked picked up"

        Problem.create(assigned_to:, body:, problem_type:, resolvable: shipment, title:)
      end
    end
  end
end
