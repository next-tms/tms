# frozen_string_literal: true

class CreateDiscussionTopics < ActiveRecord::Migration[7.0]
  def change
    create_table(:discussion_topics) do |t|
      t.references(:discussion, null: false)
      t.references(:topic, null: false, polymorphic: true)

      t.string(:contact_scope, null: false, index: true)

      t.timestamps
    end
  end
end
