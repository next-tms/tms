module ProblematicService
  class Action::Shipment::MissingPickedUpAt < Action::Shipment
    COMMENTS = {
      cancel: 'Canceling this shipment because it isn’t booked and hasn’t been picked up within one week.',
      unbook: 'Unbooking this shipment because it was booked over one week ago and hasn’t been picked up.'
    }.freeze

    def call
      return false if shipment.created_at > 1.week.ago

      if shipment.booked_at.blank?
        discussion_topic.comments.create!(body: COMMENTS[:cancel]) if discussion_topic?

        return shipment.update!(canceled_at: Time.current, updated_by: nil)
      end

      return false if shipment.booked_at > 1.week.ago

      discussion_topic.comments.create!(body: COMMENTS[:unbook]) if discussion_topic?
      shipment.update!(booked_at: nil, updated_by: nil)
    end
  end
end
