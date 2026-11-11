class Discussion < ApplicationRecord
  belongs_to :subject, polymorphic: true

  has_many :discussion_topics, dependent: :destroy
  has_many :subscriptions, as: :record, dependent: :destroy

  has_many :comments, through: :discussion_topics
end
