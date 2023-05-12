# frozen_string_literal: true

module Discussable
  extend ActiveSupport::Concern

  included do
    has_one :discussion, as: :subject, dependent: :destroy

    has_many :discussion_topics, through: :discussion
    has_many :comments, through: :discussion_topics

    after_initialize :build_discussion, if: -> { new_record? && discussion.blank? }

    def build_discussion(*args)
      return super(*args) if eligible_discussable_contacts.blank?

      record = super(*args)

      # Attributes from calling model
      record.subscriptions = eligible_discussable_contacts
                             .select(&:active?)
                             .map { |contact| record.subscriptions.new(contact:) }

      record
    end

    def discussable?
      discussion.present?
    end
  end
end
