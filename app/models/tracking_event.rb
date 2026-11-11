class TrackingEvent < ApplicationRecord
  include DiscussableTopic

  DISCUSSABLE_EVENT_ACTIVE_SHIPPING_CODES = %i[
    arrived_at_terminal
    delivered
    delivery_appointment_scheduled
    departed
    found
    located
    lost
    out_for_delivery
    pending_delivery_appointment
    picked_up
    pickup_driver_assigned
    pickup_information_received_by_carrier
    pickup_information_sent_to_carrier
    sailed
    trailer_closed
    trailer_unloaded
  ].freeze

  attr_writer :at_without_time_zone_string

  before_create :set_public

  belongs_to :event

  belongs_to :address, optional: true
  accepts_nested_attributes_for :address, allow_destroy: false, reject_if: :all_blank

  belongs_to_transponder :country, foreign_key: :country_alpha2
  belongs_to_transponder :region, foreign_key: :region_iso31662
  belongs_to :shipment
  belongs_to :terminal, optional: true
  belongs_to :user, optional: true

  validates :time_zone_name, presence: true

  def build_discussable_topic?
    return false if event.blank?

    DISCUSSABLE_EVENT_ACTIVE_SHIPPING_CODES.include?(event.active_shipping_code.to_sym)
  end

  def contact_scope
    case event.active_shipping_code
    when nil, 'delivery_appointment_scheduled', 'found', 'lost' then :broker
    else
      :any
    end
  end

  def discussable_topic_description
    key = [:discussion_topics, self.class.name.underscore.to_sym, event.active_shipping_code.to_sym].join('.')
    args = { city:, region_abbreviation: region.abbreviation, country_alpha2: country.alpha2 }

    I18n.t(key, **args)
  end

  def discussion
    shipment&.discussion
  end

  def eligible_discussable_contacts
    contacts = Contact.where(id: discussion.subscriptions.active.pluck(:contact_id))
    return contacts.broker unless event.public_by_default?

    contacts
  end

  def pretty_location
    "#{city}, #{region.abbreviation}"
  end

  def problem_type
    ProblemType.where(code: event.active_shipping_code)&.first
  end

  def time_zone
    return if time_zone_name.blank?

    ActiveSupport::TimeZone.new(time_zone_name)
  end

  private

  def set_public
    return if event.blank?

    self[:public] = event.public_by_default?
  end
end
