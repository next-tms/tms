module DiscussableTopic
  extend ActiveSupport::Concern

  included do
    has_one :discussion_topic, as: :topic
    has_many :comments, through: :discussion_topic

    before_save :build_discussion_topic, if: -> { new_record? }

    def build_discussion_topic(*args)
      return self.discussion_topic = nil unless discussion.present? && build_discussable_topic?

      record = super(*args)

      record.subscriptions = (discussion.subscriptions.active.map(&:contact) & eligible_discussable_contacts)
                             .select(&:active?)
                             .map { |contact| record.subscriptions.new(contact:) }
      record.contact_scope = contact_scope
      record.discussion = discussion

      self.discussion_topic = record
    end

    # @note Meant to be overridden in specific models
    def build_discussable_topic? = raise(NotImplementedError)

    def contact_scope = raise(NotImplementedError)
    def discussable? = discussion_topic.present?
  end
end
