class DiscussionTopic < ApplicationRecord
  belongs_to :discussion
  belongs_to :topic, polymorphic: true

  delegate :discussable_topic_description, to: :topic

  enum :contact_scope, { broker: 'broker', carrier: 'carrier', customer: 'customer', any: 'any' }

  has_many :comments, dependent: :destroy
  has_many :subscriptions, as: :record, dependent: :destroy

  has_many :contacts, through: :subscriptions

  validates :contact_scope, presence: true
end
