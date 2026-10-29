module ProblematicService
  class Action::Shipment < Action
    def shipment = @shipment ||= problem.resolvable
  end
end
