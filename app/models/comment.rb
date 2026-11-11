class Comment < ApplicationRecord
  belongs_to :discussion_topic
  belongs_to :contact

  validates :body, presence: true
end
